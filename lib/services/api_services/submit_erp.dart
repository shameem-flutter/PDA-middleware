import 'dart:developer';
import 'package:dio/dio.dart';
import 'package:pda/constants/apiclient.dart';
import 'package:pda/services/api_services/authservice.dart';
import 'package:pda/services/api_services/base_api_service.dart';
import 'package:shared_preferences/shared_preferences.dart';

enum ErpBackend { odoo, django }

class SubmitErpService {
  final BaseApiServices _api;
  final Authservice _authservice;
  final ErpBackend backend;

  SubmitErpService({
    required Future<SharedPreferences> prefs,
    required Authservice authservice,
    required this.backend,
  }) : _authservice = authservice,
       _api = BaseApiServices(prefs: prefs, dio: ApiClient.dio);

  /// Django-specific stock adjustment
  Future<bool> _createStockAdjustmentDjango({
    required List<Map<String, dynamic>> items,
  }) async {
    final prefs = await SharedPreferences.getInstance();
    final baseUrl = prefs.getString('erp_url');
    final orgId = prefs.getString('organization_id');

    if (baseUrl == null) {
      log("❌ No [Django] erp_url  found. missing in sharedpreferences.");
      return false;
    }
    final token = await _authservice.getDjangoToken();
    if (token == null || token.isEmpty) {
      log("[django] token missing");
    }

    if (orgId == null || orgId.isEmpty) {
      log("[django] organization_id is missing from SharedPreferences");
      return false;
    }

    final String url =
        "$baseUrl/api/v1/waslasoft_retail/items/update-quantity/";
    final queryParams = {"organization_id": orgId};

    // ✅ Match Postman body exactly
    final Map<String, dynamic> data = {"items": items};

    try {
      log("📤 [Django] PATCH $url with $data");

      final response = await ApiClient.dio.patch(
        url,
        queryParameters: queryParams,
        data: data,
        options: Options(
          headers: {
            "Authorization": "Token $token",
            "Content-Type": "application/json",
            "Accept": "application/json",
          },
        ),
      );

      if (response.statusCode == 200) {
        log("✅ [Django] Stock updated successfully for itemCode");
        return true;
      } else {
        log(
          "⚠️ [Django] Failed for ${response.statusCode} | Status: ${response.statusCode}, Data: ${response.data}",
        );
        return false;
      }
    } on DioException catch (e) {
      log(
        "❌ [Django] DioException updating item ${e.response?.statusCode}: ${e.response?.statusCode} - ${e.response?.data}",
      );
      return false;
    } catch (e) {
      log("❌ [Django] Unexpected error }: $e");
      return false;
    }
  }

  /// Odoo-specific stock adjustment
  Future<bool> _createStockAdjustmentOdoo({
    required String productName,
    required String barcode,
    required int countedQuantity,
  }) async {
    final data = {
      "jsonrpc": "2.0",
      "params": {
        "product_name": productName,
        "barcode": barcode,
        "counted_quantity": countedQuantity,
      },
    };

    try {
      final response = await _api.post(
        endpoint: '/api/create_stock_adjustment',
        data: data,
      );

      final success = response?.statusCode == 200;
      if (success) {
        log("✅ [Odoo] Stock updated successfully for $productName");
      } else {
        log(
          '⚠️ [Odoo] Failed for $productName (barcode: $barcode): statusCode=${response?.statusCode}, response=${response?.data}',
        );
      }
      return success;
    } catch (e) {
      log('❌ [Odoo] Error for $productName (barcode: $barcode): $e');
      return false;
    }
  }

  /// Extract barcode from session data with multiple key attempts
  String? _extractBarcode(Map<String, dynamic> session, dynamic identifier) {
    const barcodeKeys = ['barcode', 'Barcode', 'bar_code', 'BARCODE'];

    for (var key in barcodeKeys) {
      if (session.containsKey(key) &&
          session[key] is String &&
          (session[key] as String).isNotEmpty) {
        return session[key] as String;
      }
    }

    // Fallback barcode
    return 'UNKNOWN_$identifier';
  }

  /// Unified submission method that handles both backends
  Future<Map<String, dynamic>> submitToErp(
    List<Map<String, dynamic>> erpData,
  ) async {
    try {
      if (erpData.isEmpty) {
        log('submitToErp: No sessions provided');
        return {
          'success': false,
          'message': 'No sessions to submit.',
          'skippedProducts': [],
        };
      }

      final List<String> skippedProducts = [];
      List<Map<String, dynamic>> items = [];

      /// ✅ Build batch list once
      for (final session in erpData) {
        final productName = session['productName'] ?? 'Unknown';
        final itemCode = session['itemCode'] ?? session['productId'];

        if (itemCode is! int) {
          skippedProducts.add('$productName (Missing itemCode)');
          continue;
        }

        final counted = session['countedQuantity'] ?? 0;
        final erpQty = session['erpQuantity'] ?? 0;

        items.add({"item_id": itemCode, "current_stock": counted + erpQty});
      }

      bool allSuccessful = true;

      if (backend == ErpBackend.django) {
        log("🚀 Sending batch to Django: $items");

        final djangoSuccess = await _createStockAdjustmentDjango(items: items);

        if (!djangoSuccess) {
          final token = await _authservice.getDjangoToken();

          /// ❗Only fallback if token missing
          if (token == null || token.isEmpty) {
            log("⚠️ No Django token — fallback to Odoo");

            for (final session in erpData) {
              final productName = session['productName'] ?? 'Unknown';
              final productId = session['productId'];
              final counted = session['countedQuantity'] ?? 0;

              final barcode = _extractBarcode(session, productId);
              final odooSuccess = await _createStockAdjustmentOdoo(
                productName: productName,
                barcode: barcode ?? 'UNKNOWN_$productId',
                countedQuantity: counted,
              );

              if (!odooSuccess) {
                allSuccessful = false;
                skippedProducts.add("$productName (Odoo failed)");
              }
            }
          } else {
            allSuccessful = false;
          }
        }
      } else {
        /// ✅ Pure Odoo mode
        for (final session in erpData) {
          final productName = session['productName'] ?? 'Unknown';
          final productId = session['productId'];
          final counted = session['countedQuantity'] ?? 0;

          if (productId == null) {
            skippedProducts.add("$productName (Missing productId)");
            allSuccessful = false;
            continue;
          }

          final barcode = _extractBarcode(session, productId);
          final success = await _createStockAdjustmentOdoo(
            productName: productName,
            barcode: barcode ?? 'UNKNOWN_$productId',
            countedQuantity: counted,
          );

          if (!success) {
            allSuccessful = false;
            skippedProducts.add("$productName (Odoo failed)");
          }
        }
      }

      return {
        "success": allSuccessful,
        "message": allSuccessful
            ? "Stock synced successfully"
            : "Some items failed to submit",
        "skippedProducts": skippedProducts,
      };
    } catch (e) {
      log("❌ submitToErp Error: $e");
      return {
        'success': false,
        'message': 'Error submitting sessions: $e',
        'skippedProducts': [],
      };
    }
  }
}
