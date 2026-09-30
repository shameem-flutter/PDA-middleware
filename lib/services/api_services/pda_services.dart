import 'dart:developer';

import 'package:dio/dio.dart';
import 'package:pda/constants/apiclient.dart';
import 'package:pda/services/api_services/base_api_service.dart';
import 'package:pda/services/api_services/authservice.dart';
import 'package:pda/utilities/print_function.dart';
import 'package:shared_preferences/shared_preferences.dart';

class PdaServices {
  final BaseApiServices _api;
  final Future<SharedPreferences> preferences;
  final Authservice _authService;

  PdaServices(Future<SharedPreferences> prefs, this._authService)
    : _api = BaseApiServices(prefs: prefs),
      preferences = prefs;

  Future<Response?> getAllPda() async {
    final prefs = await preferences;
    final backend = prefs.getString("backend");

    if (backend == "odoo") {
      final baseUrl = prefs.getString("erp_url");
      if (baseUrl == null) {
        throw Exception("Odoo URL not found. Please log in again.");
      }

      final cleanBaseUrl = baseUrl.endsWith('/')
          ? baseUrl.substring(0, baseUrl.length - 1)
          : baseUrl;

      final Map<String, dynamic> requestBody = {"jsonrpc": "2.0", "params": {}};

      final candidateEndpoints = [
        "$cleanBaseUrl/api/get_pda_products_data",
        "$cleanBaseUrl/api/get_pda_products_data/",
        "$cleanBaseUrl/api/get_products_data",
        "$cleanBaseUrl/api/get_products_data/",
      ];

      try {
        Response? lastResponse;

        for (final url in candidateEndpoints) {
          printOrLog("🔍 Trying Odoo POST: $url");
          try {
            final res = await ApiClient.dio.post(
              url,
              options: Options(
                headers: {"Content-Type": "application/json"},
                validateStatus: (status) => status != null && status < 500,
              ),
              data: requestBody,
            );

            lastResponse = res;
            printOrLog("📡 Response Status: ${res.statusCode} for $url");

            if (res.statusCode == 200) {
              printOrLog("✅ Odoo POST succeeded on: $url");
              return res;
            }

            if (res.statusCode == 405) {
              printOrLog(
                "⚠️ 405 Method Not Allowed on POST $url — Trying GET...",
              );
              final getRes = await ApiClient.dio.get(
                url,
                options: Options(
                  headers: {"Content-Type": "application/json"},
                  validateStatus: (status) => status != null && status < 500,
                ),
              );
              if (getRes.statusCode == 200) {
                printOrLog("✅ Odoo GET succeeded on: $url");
                return getRes;
              }
            }
          } catch (e) {
            printOrLog("⚠️ Error attempting $url: $e");
          }
        }

        printOrLog("📦 Final Response Data: ${lastResponse?.data}");
        return lastResponse;
      } on DioException catch (e) {
        printOrLog(
          "❌ Odoo getAllPda DioException: ${e.response?.statusCode} - ${e.response?.data}",
        );
        return e.response;
      } catch (e) {
        printOrLog("❌ Odoo getAllPda error: $e");
        return null;
      }
    } else if (backend == "django") {
      final orgId = prefs.getString('organization_id');
      if (orgId == null || orgId.isEmpty) {
        log('[django] organization_id is missing from SharedPreferneces');
      }
      // Django code...
      String? token = await _authService.getDjangoToken();

      if (token == null || token.isEmpty) {
        throw Exception("Django token not found. Please log in again.");
      }

      return await _api.get(
        endpoint: '/api/v1/waslasoft_retail/items/',
        headers: {
          'Authorization': 'Token $token',
          "Accept": "application/json",
        },
        queryParameters: {'organization_id': orgId},
      );
    } else {
      log("⚠️ Backend missing while fetching products — probably logging out");
      return null;
    }
  }
}
