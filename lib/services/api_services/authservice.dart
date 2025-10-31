import 'dart:developer';
import 'dart:io';
import 'package:dio/dio.dart';
import 'package:pda/constants/apiclient.dart';
import 'package:shared_preferences/shared_preferences.dart';

class Authservice {
  final Dio _dio = ApiClient.dio;
  final Future<SharedPreferences> _prefs;
  Authservice(this._prefs);

  Future<bool> loginWithDjango({
    required String username,
    required String password,
    required String baseUrl,
  }) async {
    final Dio dio = Dio();
    final String url = "$baseUrl/api/login/";

    try {
      log("🔄 Attempting login with Django backend...");

      final response = await dio.post(
        url,
        data: {"username": username, "password": password},
        options: Options(
          headers: {"Content-Type": "application/json"},
          validateStatus: (status) => status != null && status < 500,
        ),
      );

      log("📡 Response: ${response.statusCode} - ${response.data}");

      if (response.statusCode == 200 && response.data != null) {
        String? token;

        if (response.data is Map) {
          token =
              response.data['token'] ??
              response.data['key'] ??
              response.data['access_token'] ??
              response.data['auth_token'];
        } else if (response.data is String) {
          token = response.data;
        }

        if (token != null && token.isNotEmpty) {
          final prefs = await _prefs;
          await prefs.setString("username", username);
          await prefs.setString("password", password);
          await prefs.setString("erp_url", baseUrl);
          await prefs.setString("token", token);

          log(
            "✅ Django login successful. Token saved: ${token.substring(0, 20)}...",
          );
          return true;
        } else {
          log("❌ Login failed — token not found in response.");
          return false;
        }
      }

      log("❌ Django login failed: ${response.data}");
      return false;
    } catch (e) {
      log("❌ Exception during Django login: $e");
      return false;
    }
  }

  /// Refresh Django token
  Future<String?> refreshDjangoToken() async {
    final prefs = await _prefs;
    final username = prefs.getString("username");
    final password = prefs.getString("password");
    final baseUrl = prefs.getString("erp_url");

    if (username == null || password == null) {
      log("❌ Cannot refresh token — missing credentials.");
      return null;
    }

    log("🔄 Refreshing Django token...");
    await prefs.remove('token');

    final success = await loginWithDjango(
      username: username,
      password: password,
      baseUrl: baseUrl.toString(),
    );
    if (success) {
      final newToken = prefs.getString('token');
      log("✅ Token refreshed successfully.");
      return newToken;
    }
    return null;
  }

  /// Get Django token (with auto-refresh if missing)
  Future<String?> getDjangoToken() async {
    final prefs = await _prefs;
    String? token = prefs.getString("token");

    if (token == null || token.isEmpty) {
      log("⚠️ Token not found — refreshing...");
      token = await refreshDjangoToken();
    }

    return token;
  }

  /// Check if token exists
  Future<bool> hasDjangoToken() async {
    final prefs = await _prefs;
    final token = prefs.getString("token");
    return token != null && token.isNotEmpty;
  }

  Future<bool> loginWithOdoo({
    required String baseUrl,
    required String db,
    required String username,
    required String password,
  }) async {
    final String url = "$baseUrl/web/session/authenticate";
    final data = {
      "jsonrpc": "2.0",
      "params": {"db": db, "login": username, "password": password},
    };

    try {
      final response = await _dio.post(
        url,
        data: data,
        options: Options(headers: {"Content-Type": "application/json"}),
      );

      if (response.statusCode == 200 && response.data["result"] != null) {
        log(
          "Login successful. CookieManager has automatically saved the session.",
        );

        ApiClient.updateBaseUrl(baseUrl);

        final prefs = await _prefs;
        await prefs.setString("username", username);
        await prefs.setString("erp_url", baseUrl);
        await prefs.setString("db", db);

        var sessionId = response.data['result']['session_id'];
        if (sessionId == null) {
          final cookies = await ApiClient.cookieJar.loadForRequest(
            Uri.parse(baseUrl),
          );
          final sessionCookie = cookies.firstWhere(
            (cookie) => cookie.name == "session_id",
            orElse: () => Cookie("session_id", ""),
          );
          if (sessionCookie.value.isNotEmpty) {
            sessionId = sessionCookie.value;
            log("Extracted session_id from CookieJar: $sessionId");
          }
        }

        if (sessionId != null) {
          final uri = Uri.parse(baseUrl);
          final sessionCookie = Cookie("session_id", sessionId);
          await ApiClient.cookieJar.saveFromResponse(uri, [sessionCookie]);
          await prefs.setString("session_id", sessionId);
          await prefs.setString("erp_url", baseUrl);
          await prefs.setString("db", db);
          return true;
        } else {
          log("⚠️ No session_id found in JSON or cookies.");
          return false;
        }
      }

      if (response.data["error"] != null) {
        log("Server returned an error: ${response.data['error']['message']}");
      }

      return false;
    } catch (e) {
      log("Login failed with an exception: $e");
      return false;
    }
  }

  Future<bool> login({
    required String baseUrl,
    String? db,
    required String username,
    required String password,
  }) async {
    final djangoSuccess = await loginWithDjango(
      username: username,
      password: password,
      baseUrl: baseUrl,
    );
    if (djangoSuccess) {
      return true;
    }
    if (db != null && db.isNotEmpty) {
      return await loginWithOdoo(
        baseUrl: baseUrl,
        db: db,
        username: username,
        password: password,
      );
    }
    return false;
  }

  Future<void> logOut() async {
    final prefs = await _prefs;
    final baseUrl = prefs.getString("erp_url");
    final isOdoo =
        prefs.getString("db") != null && prefs.getString("db")!.isNotEmpty;

    if (isOdoo && baseUrl != null) {
      const String endpoint = "/web/session/destroy";

      try {
        await _dio.post(
          "$baseUrl$endpoint",
          data: {"jsonrpc": "2.0", "params": {}},
        );
      } catch (e) {
        log("Odoo logout failed: $e");
      }
    }

    // Clear the session from the manager AND from local storage
    await ApiClient.cookieJar.deleteAll();
    await prefs.clear();
    log("Session data cleared");
  }

  Future<String?> getSessionId() async {
    return (await _prefs).getString("session_id");
  }
}
