import 'package:dio/dio.dart';
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
    final prefs =
        await SharedPreferences.getInstance(); // Add this: Assuming _prefs from constructor (SharedPreferences)
    final db = prefs.getString("db");
    final isOdoo = db != null && db.isNotEmpty;

    String? token;
    if (!isOdoo) {
      // ✅ Simple if: Only get token for Django
      token = await _authService.getDjangoToken();
      if (token == null || token.isEmpty) {
        throw Exception("Django token not found. Please log in again.");
      }
      printOrLog("🔑 Token: ${token.substring(0, 20)}...");
    } else {
      printOrLog("🍪 Odoo detected—skipping token, using session cookies.");
    }

    printOrLog("🔄 Fetching products from API (${isOdoo ? 'Odoo' : 'Django'})");

    // Build headers conditionally
    final Map<String, String> headers = {
      "Accept": "application/json",
      if (!isOdoo && token != null)
        'Authorization': 'Token $token', // ✅ Only for Django
    };

    final response = await _api.get(
      endpoint: 'api/v1/waslasoft_retail/items/',
      headers: headers,
      queryParameters: {'organization_id': 'WASL6A81F8A9'},
    );

    printOrLog("📡 Response Status: ${response?.statusCode}");

    // ✅ Handle 401 - Only for Django (skip refresh for Odoo)
    if (response?.statusCode == 401 && !isOdoo) {
      printOrLog("⚠️ Token invalid (401), attempting to refresh...");
      token = await _authService.refreshDjangoToken();
      if (token != null) {
        printOrLog("🔄 Retrying with refreshed token...");
        return await _api.get(
          endpoint: 'api/v1/waslasoft_retail/items/',
          headers: {
            'Authorization': 'Token $token',
            "Accept": "application/json",
          },
          queryParameters: {'organization_id': 'WASL6A81F8A9'},
        );
      } else {
        throw Exception(
          "Token expired and refresh failed. Please log in again.",
        );
      }
    } else if (response?.statusCode == 401 && isOdoo) {
      // Odoo: Session expired
      printOrLog("⚠️ Odoo session expired (401). Please log in again.");
      throw Exception("Odoo session expired. Please log in again.");
    }

    if (response?.data != null) {
      if (response!.data is Map) {
        printOrLog(
          "📦 Response is a Map with keys: ${(response.data as Map).keys}",
        );
        if ((response.data as Map).containsKey('data')) {
          final dataList = (response.data as Map)['data'];
          printOrLog(
            "📊 Data array length: ${dataList is List ? dataList.length : 'not a list'}",
          );
        }
      }
    } else {
      printOrLog("⚠️ Response data is null");
    }

    return response;
  }
}
