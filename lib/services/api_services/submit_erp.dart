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
    required int itemCode,
    required int countedQuantity,
    required int erpQuantity,
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

    final String url = "$baseUrl/api/v1/waslasoft_retail/items/$itemCode/";
    final queryParams = {"organization_id": orgId};

    // ✅ Match Postman body exactly
    final Map<String, dynamic> data = {
      "current_stock": countedQuantity + erpQuantity,
    };

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
        log("✅ [Django] Stock updated successfully for itemCode: $itemCode");
        return true;
      } else {
        log(
          "⚠️ [Django] Failed for $itemCode | Status: ${response.statusCode}, Data: ${response.data}",
        );
        return false;
      }
    } on DioException catch (e) {
      log(
        "❌ [Django] DioException updating item $itemCode: ${e.response?.statusCode} - ${e.response?.data}",
      );
      return false;
    } catch (e) {
      log("❌ [Django] Unexpected error updating item $itemCode: $e");
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

      bool allSuccessful = true;
      final List<String> skippedProducts = [];

      for (final session in erpData) {
        log('submitToErp [$backend]: Processing session: $session');

        final productName =
            session['productName'] as String? ?? 'Unknown Product';
        final countedQuantity = session['countedQuantity'] as int? ?? 0;

        bool success = false;

        // 🧭 Always prefer actual backend setting
        if (backend == ErpBackend.django) {
          final itemCode = session['itemCode'] ?? session['productId'];
          if (itemCode is! int) {
            log(
              'submitToErp [Django]: Invalid or missing itemCode for $productName',
            );
            skippedProducts.add('$productName (Missing itemCode)');
            allSuccessful = false;
            continue;
          }

          final erpQuantity = session['erpQuantity'] as int? ?? 0;

          // 🧩 Try Django first
          success = await _createStockAdjustmentDjango(
            itemCode: itemCode,
            countedQuantity: countedQuantity,
            erpQuantity: erpQuantity,
          );

          // ⚙️ If Django failed due to missing token, fallback to Odoo
          if (!success) {
            final token = await _authservice.getDjangoToken();
            if (token == null || token.isEmpty) {
              log(
                "🔁 No Django token — falling back to Odoo submission for $productName",
              );
              final barcode = _extractBarcode(session, itemCode);
              success = await _createStockAdjustmentOdoo(
                productName: productName,
                barcode: barcode ?? 'UNKNOWN_$itemCode',
                countedQuantity: countedQuantity,
              );
            }
          }
        } else {
          // 🧩 Odoo main flow
          final productId = session['productId'] as int?;
          if (productId == null) {
            log(
              'submitToErp [Odoo]: Skipping session, missing productId for $productName',
            );
            skippedProducts.add('$productName (Missing productId)');
            allSuccessful = false;
            continue;
          }

          final barcode = _extractBarcode(session, productId);
          success = await _createStockAdjustmentOdoo(
            productName: productName,
            barcode: barcode ?? 'UNKNOWN_$productId',
            countedQuantity: countedQuantity,
          );
        }

        if (!success) {
          log('submitToErp [$backend]: Failed to submit $productName');
          skippedProducts.add('$productName (Submission failed)');
          allSuccessful = false;
        } else {
          final usedBackend =
              (backend == ErpBackend.django &&
                  (await _authservice.getDjangoToken()) == null)
              ? ErpBackend.odoo
              : backend;
          log(
            'submitToErp [${usedBackend.name.toUpperCase()}]: Successfully submitted $productName',
          );
        }
      }

      if (allSuccessful) {
        log('submitToErp [$backend]: All sessions submitted successfully');
        return {
          'success': true,
          'message': 'Successfully submitted to ERP',
          'skippedProducts': skippedProducts,
        };
      } else {
        log('submitToErp [$backend]: Some sessions failed: $skippedProducts');
        return {
          'success': false,
          'message': 'Some sessions failed to submit.',
          'skippedProducts': skippedProducts,
        };
      }
    } catch (e) {
      log('submitToErp [$backend]: Error submitting sessions: $e');
      return {
        'success': false,
        'message': 'Error submitting sessions: $e',
        'skippedProducts': [],
      };
    }
  }
}
