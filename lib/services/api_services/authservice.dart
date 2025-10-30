import 'dart:developer';
import 'package:dio/dio.dart';
import 'package:shared_preferences/shared_preferences.dart';

class Authservice {
  // final Dio _dio = ApiClient.dio;
  final Future<SharedPreferences> _prefs;
  Authservice(this._prefs);

  /// Django-only login
  Future<bool> login({
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

    final success = await login(
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

  /// Logout (clear session)
  Future<void> logOut() async {
    final prefs = await _prefs;
    await prefs.clear();
    log("✅ Logged out and cleared Django session data.");
  }
}
