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
    final db = prefs.getString("db");
    final isOdoo = db != null && db.isNotEmpty;

    if (isOdoo) {
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
      printOrLog("  Database: $db");
      printOrLog("  Request Body: $requestBody");

      final response = await ApiClient.dio.request(
        fullUrl,
        options: Options(
          method: 'GET',
          headers: {"Content-Type": "application/json"},
        ),
        data: requestBody,
      );

      printOrLog("📡 Response Status: ${response.statusCode}");
      printOrLog("📦 Response Data: ${response.data}");

      return response;
    } else {
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
        queryParameters: {'organization_id': 'WASL6A81F8A9'},
      );
    }
  }
}
