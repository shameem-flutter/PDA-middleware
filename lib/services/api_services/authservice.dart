import 'dart:developer';
import 'dart:io';
import 'package:dio/dio.dart';
import 'package:pda/constants/apiclient.dart';
import 'package:pda/services/secure_storage_service.dart';
import 'package:pda/utilities/print_function.dart';
import 'package:shared_preferences/shared_preferences.dart';

class Authservice {
  final Dio _dio = ApiClient.dio;
  final Future<SharedPreferences> _prefs;
  final SecureStorageService _secureStorage = SecureStorageService();

  Authservice(this._prefs);

  Future<void> _switchBackend({
    required SharedPreferences prefs,
    required String backend, // "django" or "odoo"
  }) async {
    // Clear old backend credentials securely
    await _secureStorage.delete(SecureStorageService.keyToken, prefs: prefs); // Django
    await _secureStorage.delete(SecureStorageService.keySessionId, prefs: prefs); // Odoo
    await prefs.remove("db"); // Odoo

    // Save new backend flag
    await prefs.setString("backend", backend);

    // Clear cookies to avoid mixing sessions
    try {
      await ApiClient.cookieJar.deleteAll();
    } catch (_) {}

    printOrLog("✅ Switched backend to $backend");
  }

  Future<bool> loginWithDjango({
    required String username,
    required String password,
    required String baseUrl,
  }) async {
    final Dio dio = ApiClient.dio;
    final String url = "$baseUrl/api/login/";

    try {
      printOrLog("🔄 Attempting login with Django backend...");

      final response = await dio.post(
        url,
        data: {"username": username, "password": password},
        options: Options(
          headers: {"Content-Type": "application/json"},
          validateStatus: (status) => status != null && status < 500,
        ),
      );

      printOrLog("📡 Response: ${response.statusCode}");

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
          await _switchBackend(prefs: prefs, backend: "django");
          await prefs.setString("username", username);
          await prefs.setString("erp_url", baseUrl);
          
          // Securely store sensitive credentials
          await _secureStorage.write(
            key: SecureStorageService.keyPassword,
            value: password,
            prefs: prefs,
          );
          await _secureStorage.write(
            key: SecureStorageService.keyToken,
            value: token,
            prefs: prefs,
          );

          printOrLog("✅ Django login successful.");
          return true;
        } else {
          printOrLog("❌ Login failed — token not found in response.");
          return false;
        }
      }

      printOrLog("❌ Django login failed");
      return false;
    } catch (e) {
      printOrLog("❌ Exception during Django login: $e");
      return false;
    }
  }

  /// Refresh Django token
  Future<String?> refreshDjangoToken() async {
    final prefs = await _prefs;
    final username = prefs.getString("username");
    final password = await _secureStorage.read(
      SecureStorageService.keyPassword,
      prefs: prefs,
    );
    final baseUrl = prefs.getString("erp_url");

    if (username == null || password == null || baseUrl == null) {
      printOrLog("❌ Cannot refresh token — missing credentials or base URL.");
      return null;
    }

    printOrLog("🔄 Refreshing Django token...");
    await _secureStorage.delete(SecureStorageService.keyToken, prefs: prefs);

    final success = await loginWithDjango(
      username: username,
      password: password,
      baseUrl: baseUrl,
    );
    if (success) {
      final newToken = await _secureStorage.read(
        SecureStorageService.keyToken,
        prefs: prefs,
      );
      printOrLog("✅ Token refreshed successfully.");
      return newToken;
    }
    return null;
  }

  /// Get Django token (with auto-refresh if missing)
  Future<String?> getDjangoToken() async {
    final prefs = await _prefs;
    String? token = await _secureStorage.read(
      SecureStorageService.keyToken,
      prefs: prefs,
    );

    if (token == null || token.isEmpty) {
      printOrLog("⚠️ Token not found — refreshing...");
      token = await refreshDjangoToken();
    }

    return token;
  }

  /// Check if token exists
  Future<bool> hasDjangoToken() async {
    final prefs = await _prefs;
    final token = await _secureStorage.read(
      SecureStorageService.keyToken,
      prefs: prefs,
    );
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
          await _secureStorage.write(
            key: SecureStorageService.keySessionId,
            value: sessionId,
            prefs: prefs,
          );
          return true;
        } else {
          printOrLog("⚠️ No session_id found in JSON or cookies.");
          return false;
        }
      }

      if (response.data["error"] != null) {
        printOrLog("Server returned an error: ${response.data['error']['message']}");
      }

      return false;
    } catch (e) {
      printOrLog("Login failed with an exception: $e");
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
      printOrLog("log in failed db/ organization id is required");
      return false;
    }

    final prefs = await _prefs;
    final bool isDjango =
        baseUrl.contains("middleware.febnohost.com") ||
        baseUrl.contains("/api/login/");

    if (isDjango) {
      final djangoSuccess = await loginWithDjango(
        username: username,
        password: password,
        baseUrl: baseUrl,
      );
      if (djangoSuccess) {
        await prefs.setString('backend', 'django');
        await prefs.setString("organization_id", db);
        printOrLog("django login success");
        return true;
      }
      printOrLog("Django login failed");
      return false;
    }

    printOrLog("Odoo login selected");

    final odooSuccess = await loginWithOdoo(
      baseUrl: baseUrl,
      db: db,
      username: username,
      password: password,
    );
    if (odooSuccess) {
      await prefs.setString('backend', 'odoo');
      printOrLog("log in with odoo success");
      return true;
    }

    return false;
  }

  /// ✅ Thorough logout that clears local session and secure credentials
  Future<void> logOut() async {
    final prefs = await _prefs;
    final baseUrl = prefs.getString("erp_url");
    final db = prefs.getString("db");
    final token = await _secureStorage.read(
      SecureStorageService.keyToken,
      prefs: prefs,
    );

    printOrLog("🔄 Starting logout process...");

    try {
      // 🔹 Attempt Odoo logout
      if (db != null && db.isNotEmpty && baseUrl != null) {
        const String endpoint = "/web/session/destroy";
        printOrLog("🔄 Logging out from Odoo...");

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
            printOrLog("✅ Odoo logout successful.");
          } else {
            printOrLog("⚠️ Odoo logout failed: ${response.statusCode}");
          }
        } catch (e) {
          printOrLog("⚠️ Odoo logout error (continuing cleanup): $e");
        }
      }

      // 🔹 Attempt Django logout
      if (token != null && token.isNotEmpty && baseUrl != null) {
        final logoutUrl = "$baseUrl/api/logout/";
        printOrLog("🔄 Logging out from Django...");

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
            printOrLog("✅ Django logout successful.");
          } else {
            printOrLog("⚠️ Django logout failed: ${response.statusCode}");
          }
        } catch (e) {
          printOrLog("⚠️ Django logout error (continuing cleanup): $e");
        }
      }
    } catch (e) {
      printOrLog("⚠️ Unexpected error during logout: $e");
    } finally {
      printOrLog("🧹 Clearing all local session data...");

      try {
        await ApiClient.cookieJar.deleteAll();
        printOrLog("✅ Cookies cleared");
      } catch (e) {
        printOrLog("⚠️ Error clearing cookies: $e");
      }

      try {
        await _secureStorage.deleteAll(prefs: prefs);

        final keysToRemove = [
          "erp_url",
          "db",
          "username",
          "backend",
          "organization_id",
          "first_run",
        ];

        for (final key in keysToRemove) {
          await prefs.remove(key);
        }

        printOrLog("✅ SharedPreferences cleared (individual keys)");
      } catch (e) {
        printOrLog("⚠️ Error clearing individual keys: $e");
      }

      printOrLog("✅ Logout complete - all local session data cleared.");
    }
  }

  /// ✅ Check if user has valid credentials
  Future<bool> hasValidSession() async {
    final prefs = await _prefs;
    final token = await _secureStorage.read(
      SecureStorageService.keyToken,
      prefs: prefs,
    );
    final sessionId = await _secureStorage.read(
      SecureStorageService.keySessionId,
      prefs: prefs,
    );
    final erpUrl = prefs.getString("erp_url");
    final backend = prefs.getString("backend");

    final hasCredentials =
        (token != null && token.isNotEmpty) ||
        (sessionId != null && sessionId.isNotEmpty);
    final hasUrl = erpUrl != null && erpUrl.isNotEmpty;
    final hasBackend = backend != null && backend.isNotEmpty;

    return hasCredentials && hasUrl && hasBackend;
  }

  Future<String?> getSessionId() async {
    final prefs = await _prefs;
    return await _secureStorage.read(
      SecureStorageService.keySessionId,
      prefs: prefs,
    );
  }

  /// ✅ Get current backend type
  Future<String?> getBackend() async {
    final prefs = await _prefs;
    return prefs.getString("backend");
  }

  /// ✅ Get organization ID
  Future<String?> getOrganizationId() async {
    final prefs = await _prefs;
    return prefs.getString("organization_id");
  }

  /// ✅ Refresh token (works for both backends)
  Future<bool> refreshToken() async {
    final backend = await getBackend();

    if (backend == "django") {
      final token = await refreshDjangoToken();
      return token != null;
    } else if (backend == "odoo") {
      final prefs = await _prefs;
      final username = prefs.getString("username");
      final password = await _secureStorage.read(
        SecureStorageService.keyPassword,
        prefs: prefs,
      );
      final baseUrl = prefs.getString("erp_url");
      final db = prefs.getString("db");

      if (username == null ||
          password == null ||
          baseUrl == null ||
          db == null) {
        printOrLog("❌ Cannot refresh Odoo session — missing credentials.");
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
