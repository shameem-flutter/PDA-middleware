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

      final fullUrl = "$baseUrl/api/get_products_data";

      final Map<String, dynamic> requestBody = {"jsonrpc": "2.0", "params": {}};

      final cookies = await ApiClient.cookieJar.loadForRequest(
        Uri.parse(baseUrl),
      );
      printOrLog("🍪 Cookies being sent:");
      for (var cookie in cookies) {
        printOrLog("  ${cookie.name} = ${cookie.value}");
      }

      // ✅ Add detailed logging
      printOrLog("🔍 Odoo Request Details:");
      printOrLog("  Full URL: $fullUrl");

      printOrLog("  Request Body: $requestBody");

      try {
        final response = await ApiClient.dio.post(
          fullUrl,
          options: Options(
            headers: {"Content-Type": "application/json"},
            validateStatus: (status) => status != null && status < 500,
          ),
          data: requestBody,
        );

        printOrLog("📡 Response Status: ${response.statusCode}");
        printOrLog("📦 Response Data: ${response.data}");

        return response;
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
