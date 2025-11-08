import 'dart:developer';
import 'dart:io';
import 'package:dio/dio.dart';
import 'package:pda/constants/apiclient.dart';
import 'package:shared_preferences/shared_preferences.dart';

class Authservice {
  final Dio _dio = ApiClient.dio;
  final Future<SharedPreferences> _prefs;
  Authservice(this._prefs);

  Future<void> _switchBackend({
    required SharedPreferences prefs,
    required String backend, // "django" or "odoo"
  }) async {
    // Clear old backend credentials
    await prefs.remove("token"); // Django
    await prefs.remove("session_id"); // Odoo
    await prefs.remove("db"); // Odoo

    // Save new backend flag
    await prefs.setString("backend", backend);

    // Clear cookies to avoid mixing sessions
    try {
      await ApiClient.cookieJar.deleteAll();
    } catch (_) {}

    log("✅ Switched backend to $backend");
  }

  Future<bool> loginWithDjango({
    required String username,
    required String password,
    required String baseUrl,
  }) async {
    final Dio dio = ApiClient.dio;
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
          await _switchBackend(prefs: prefs, backend: "odoo");
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
        await prefs.setString("organization_id", db);

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
    required String db,
    required String username,
    required String password,
  }) async {
    if (db.isEmpty) {
      log("log in failed db/ organization id is required");
      return false;
    }

    final prefs = await _prefs;
    final bool isDjango = baseUrl.contains("http://middleware.febnohost.com");

    if (isDjango) {
      final djangoSuccess = await loginWithDjango(
        username: username,
        password: password,
        baseUrl: baseUrl,
      );
      if (djangoSuccess) {
        await prefs.setString('backend', 'django');
        await prefs.setString("organization_id", db);
        log("django login success");
        return true;
      }
      log("Django login failed");
      return false;
    }

    log("Odoo login selected");

    final odooSuccess = await loginWithOdoo(
      baseUrl: baseUrl,
      db: db,
      username: username,
      password: password,
    );
    if (odooSuccess) {
      final prefs = await _prefs;
      await prefs.setString('backend', 'odoo');
      await prefs.setString("db", db);
      await prefs.setString("organization_id", db);
      log("log in with odoo success");
      return true;
    }

    return false;
  }

  /// ✅ IMPROVED: Thorough logout that clears everything
  Future<void> logOut() async {
    final prefs = await _prefs;
    final baseUrl = prefs.getString("erp_url");
    final db = prefs.getString("db");
    final token = prefs.getString("token");

    log("🔄 Starting logout process...");

    try {
      // 🔹 Attempt Odoo logout
      if (db != null && db.isNotEmpty && baseUrl != null) {
        const String endpoint = "/web/session/destroy";
        log("🔄 Logging out from Odoo...");

        try {
          final response = await _dio.post(
            "$baseUrl$endpoint",
            data: {"jsonrpc": "2.0", "params": {}},
            options: Options(
              headers: {"Content-Type": "application/json"},
              validateStatus: (status) => status != null && status < 500,
            ),
          );

          if (response.statusCode == 200) {
            log("✅ Odoo logout successful.");
          } else {
            log("⚠️ Odoo logout failed: ${response.statusCode}");
          }
        } catch (e) {
          log("⚠️ Odoo logout error (continuing cleanup): $e");
        }
      }

      // 🔹 Attempt Django logout
      if (token != null && token.isNotEmpty && baseUrl != null) {
        final logoutUrl = "$baseUrl/api/logout/";
        log("🔄 Logging out from Django...");

        try {
          final response = await _dio.post(
            logoutUrl,
            options: Options(
              headers: {
                "Authorization": "Token $token",
                "Content-Type": "application/json",
              },
              validateStatus: (status) => status != null && status < 500,
            ),
          );

          if (response.statusCode == 200) {
            log("✅ Django logout successful.");
          } else {
            log("⚠️ Django logout failed: ${response.statusCode}");
          }
        } catch (e) {
          log("⚠️ Django logout error (continuing cleanup): $e");
        }
      }
    } catch (e) {
      log("⚠️ Unexpected error during logout: $e");
    } finally {
      // ✅ ALWAYS clear local data, even if server logout fails
      log("🧹 Clearing all local session data...");

      try {
        // Clear all cookies
        await ApiClient.cookieJar.deleteAll();
        log("✅ Cookies cleared");
      } catch (e) {
        log("⚠️ Error clearing cookies: $e");
      }

      try {
        // Clear all SharedPreferences - Method 1: Individual removes
        await prefs.remove("token");
        await prefs.remove("session_id");
        await prefs.remove("erp_url");
        await prefs.remove("db");
        await prefs.remove("username");
        await prefs.remove("password");
        await prefs.remove("backend");

        // Also clear any other app-specific keys you might have
        await prefs.remove("first_run");

        log("✅ SharedPreferences cleared (individual keys)");
      } catch (e) {
        log("⚠️ Error clearing individual keys: $e");
      }

      try {
        // Clear all SharedPreferences - Method 2: Clear everything (more thorough)
        final allKeys = prefs.getKeys();
        log("🔍 Clearing ${allKeys.length} SharedPreferences keys: $allKeys");

        for (final key in allKeys) {
          await prefs.remove(key);
        }

        log("✅ All SharedPreferences cleared");
      } catch (e) {
        log("⚠️ Error clearing all SharedPreferences: $e");
      }

      log("✅ Logout complete - all local session data cleared.");
    }
  }

  /// ✅ NEW: Check if user has valid credentials
  Future<bool> hasValidSession() async {
    final prefs = await _prefs;
    final token = prefs.getString("token");
    final sessionId = prefs.getString("session_id");
    final erpUrl = prefs.getString("erp_url");
    final backend = prefs.getString("backend");

    // Must have either token or sessionId, AND must have erp_url
    final hasCredentials =
        (token != null && token.isNotEmpty) ||
        (sessionId != null && sessionId.isNotEmpty);
    final hasUrl = erpUrl != null && erpUrl.isNotEmpty;
    final hasBackend = backend != null && backend.isNotEmpty;

    return hasCredentials && hasUrl && hasBackend;
  }

  Future<String?> getSessionId() async {
    return (await _prefs).getString("session_id");
  }

  /// ✅ NEW: Get current backend type
  Future<String?> getBackend() async {
    final prefs = await _prefs;
    return prefs.getString("backend");
  }

  /// ✅ NEW: Refresh token (works for both backends)
  Future<bool> refreshToken() async {
    final backend = await getBackend();

    if (backend == "django") {
      final token = await refreshDjangoToken();
      return token != null;
    } else if (backend == "odoo") {
      // For Odoo, we need to re-authenticate
      final prefs = await _prefs;
      final username = prefs.getString("username");
      final password = prefs.getString("password");
      final baseUrl = prefs.getString("erp_url");
      final db = prefs.getString("db");

      if (username == null ||
          password == null ||
          baseUrl == null ||
          db == null) {
        log("❌ Cannot refresh Odoo session — missing credentials.");
        return false;
      }

      return await loginWithOdoo(
        baseUrl: baseUrl,
        db: db,
        username: username,
        password: password,
      );
    }

    return false;
  }
}
