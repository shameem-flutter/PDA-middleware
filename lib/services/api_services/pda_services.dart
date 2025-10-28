import 'package:dio/dio.dart';
import 'package:pda/services/api_services/base_api_service.dart';
import 'package:shared_preferences/shared_preferences.dart';

class PdaServices {
  final BaseApiServices _api;
  final Future<SharedPreferences> _prefs;

  PdaServices(Future<SharedPreferences> prefs)
    : _api = BaseApiServices(prefs: prefs),
      _prefs = prefs;

  Future<Response?> getAllPda() async {
    final dbName = (await _prefs).getString("db");
    if (dbName == null) {
      throw Exception("Database name not found. Please log in again.");
    }

    final Map<String, dynamic> requestBody = {
      "jsonrpc": "2.0",
      "params": {"db": dbName},
    };

    return _api.get(endpoint: '/api/get_products_data', data: requestBody);
  }

  Future<Response?> getProductByBarcode(String barcode) async {
    final dbName = (await _prefs).getString("db");
    if (dbName == null) {
      throw Exception("Database name not found. Please log in again.");
    }

    final Map<String, dynamic> requestBody = {
      "jsonrpc": "2.0",
      "params": {"db": dbName, "barcode": barcode},
    };

    return _api.get(endpoint: '/api/get_product_by_barcode', data: requestBody);
  }
}
