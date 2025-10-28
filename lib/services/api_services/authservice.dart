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
          await prefs.setString("session_id", sessionId);
          await prefs.setString("erp_url", baseUrl);
          await prefs.setString("db", db);
        } else {
          log("⚠️ No session_id found in JSON or cookies.");
        }

        return true;
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

  // ✅ THIS IS THE MISSING LOGOUT METHOD
  Future<void> logOut() async {
    final prefs = await _prefs;
    final baseUrl = prefs.getString("erp_url");
    const String endpoint = "/web/session/destroy";

    if (baseUrl != null) {
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
