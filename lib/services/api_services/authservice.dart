import 'dart:developer';
import 'package:cookie_jar/cookie_jar.dart';
import 'package:dio/dio.dart';
import 'package:pda/constants/apiclient.dart';
import 'package:shared_preferences/shared_preferences.dart';

class Authservice {
  final Dio _dio = ApiClient.dio;
  final Future<SharedPreferences> _prefs;
  Authservice(this._prefs);

  Future<bool> login({
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
      // 1️⃣ Login to Odoo
      final response = await _dio.post(
        url,
        data: data,
        options: Options(headers: {"Content-Type": "application/json"}),
      );

      if (response.statusCode == 200 && response.data["result"] != null) {
        log(
          "✅ Odoo login successful. CookieManager has automatically saved the session.",
        );

        ApiClient.updateBaseUrl(baseUrl);

        final prefs = await _prefs;
        await prefs.setString("erp_url", baseUrl);
        await prefs.setString("db", db);
        await prefs.setString("username", username);
        // ⚠️ Store password for Django token generation
        await prefs.setString("password", password);

        // Extract session_id
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
          await prefs.setString("session_id", sessionId);
        } else {
          log("⚠️ No session_id found in JSON or cookies.");
        }

        // 2️⃣ Get Django token (doesn't use db parameter)
        final djangoTokenSuccess = await _getDjangoToken(
          username: username,
          password: password,
        );

        if (!djangoTokenSuccess) {
          log("⚠️ Failed to get Django token, but Odoo login succeeded");
          // Continue anyway - products will fail but Odoo works
        }

        return true;
      }

      if (response.data["error"] != null) {
        log("❌ Server returned an error: ${response.data['error']['message']}");
      }

      return false;
    } catch (e) {
      log("❌ Login failed with an exception: $e");
      return false;
    }
  }

  /// Get Django authentication token (no db needed)
  Future<bool> _getDjangoToken({
    required String username,
    required String password,
  }) async {
    try {
      log("🔄 Fetching Django token for user: $username");

      // ✅ Django doesn't need 'db' parameter
      final response = await _dio.post(
        'http://middleware.febnohost.com/api/login/',
        data: {
          "username": username,
          "password": password,
          // Note: No 'db' field needed for Django
        },
        options: Options(headers: {"Content-Type": "application/json"}),
      );

      if (response.statusCode == 200 && response.data != null) {
        // Try to extract token from different possible response formats
        String? token;

        if (response.data is Map) {
          token =
              response.data['token'] as String? ??
              response.data['key'] as String? ??
              response.data['access_token'] as String? ??
              response.data['auth_token'] as String?;
        } else if (response.data is String) {
          token = response.data;
        }

        if (token != null && token.isNotEmpty) {
          final prefs = await _prefs;
          await prefs.setString('token', token);
          log(
            "✅ Django token obtained and saved: ${token.substring(0, 20)}...",
          );
          return true;
        } else {
          log("❌ No token found in Django response");
          log("Response data: ${response.data}");
          return false;
        }
      } else {
        log(
          "❌ Django authentication failed with status: ${response.statusCode}",
        );
        log("Response: ${response.data}");
        return false;
      }
    } catch (e) {
      log("❌ Error fetching Django token: $e");
      return false;
    }
  }

  /// Refresh Django token if expired
  Future<String?> refreshDjangoToken() async {
    final prefs = await _prefs;
    final username = prefs.getString("username");
    final password = prefs.getString("password");

    if (username == null || password == null) {
      log("❌ Cannot refresh Django token: credentials not found");
      return null;
    }

    log("🔄 Refreshing Django token...");
    await prefs.remove('token');

    final success = await _getDjangoToken(
      username: username,
      password: password,
    );

    if (success) {
      return prefs.getString('token');
    }

    return null;
  }

  /// Validate if Django token exists
  Future<bool> hasDjangoToken() async {
    final prefs = await _prefs;
    final token = prefs.getString("token");
    return token != null && token.isNotEmpty;
  }

  /// Get Django token (with auto-refresh if needed)
  Future<String?> getDjangoToken() async {
    final prefs = await _prefs;
    String? token = prefs.getString("token");

    if (token == null || token.isEmpty) {
      log("⚠️ Django token not found, attempting to fetch...");
      token = await refreshDjangoToken();
    }

    return token;
  }

  /// Logout from both Odoo and clear Django token
  Future<void> logOut() async {
    final prefs = await _prefs;
    final baseUrl = prefs.getString("erp_url");
    const String endpoint = "/web/session/destroy";

    // 1️⃣ Logout from Odoo
    if (baseUrl != null) {
      try {
        await _dio.post(
          "$baseUrl$endpoint",
          data: {"jsonrpc": "2.0", "params": {}},
        );
        log("✅ Odoo logout successful");
      } catch (e) {
        log("⚠️ Odoo logout failed: $e");
      }
    }

    // 2️⃣ Clear all session data
    await ApiClient.cookieJar.deleteAll();
    await prefs.clear();
    log("✅ All session data cleared (Odoo + Django)");
  }

  Future<String?> getSessionId() async {
    return (await _prefs).getString("session_id");
  }
}
