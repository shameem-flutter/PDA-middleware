import 'dart:developer';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:pda/constants/apiclient.dart';
import 'package:pda/providers/providers.dart';
import 'package:pda/services/api_services/base_api_service.dart';
import 'package:shared_preferences/shared_preferences.dart';

class SubmitErpService {
  final BaseApiServices _api;

  SubmitErpService(Future<SharedPreferences> prefs)
    : _api = BaseApiServices(prefs: prefs, dio: ApiClient.dio);

  Future<bool> createStockAdjustment({
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
      if (!success) {
        log(
          'createStockAdjustment failed for $productName (barcode: $barcode): statusCode=${response?.statusCode}, response=${response?.data}',
        );
      }
      return success;
    } catch (e) {
      log(
        'createStockAdjustment error for $productName (barcode: $barcode): $e',
      );
      return false;
    }
  }

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
        log('submitToErp: Processing session: $session');
        final productId = session['productId'] as int?;
        final productName =
            session['productName'] as String? ?? 'Unknown Product';
        final countedQuantity = session['countedQuantity'] as int? ?? 0;

        // Check for barcode under multiple possible keys
        String? barcode;
        for (var key in ['barcode', 'Barcode', 'bar_code', 'BARCODE']) {
          if (session.containsKey(key) &&
              session[key] is String &&
              session[key].isNotEmpty) {
            barcode = session[key] as String;
            break;
          }
        }

        if (productId == null) {
          log(
            'submitToErp: Skipping session, missing productId for $productName',
          );
          skippedProducts.add('$productName (Missing productId)');
          allSuccessful = false;
          continue;
        }

        if (barcode == null || barcode.isEmpty) {
          log(
            'submitToErp: Invalid barcode for $productName (productId: $productId), barcode: $barcode, session keys: ${session.keys}',
          );
          barcode = 'UNKNOWN_$productId';
          log('submitToErp: Using fallback barcode: $barcode');
          skippedProducts.add('$productName (Invalid barcode, used $barcode)');
          // Proceed with fallback barcode
        }

        log(
          'submitToErp: Submitting $productName (productId: $productId, barcode: $barcode, quantity: $countedQuantity)',
        );
        final success = await createStockAdjustment(
          productName: productName,
          barcode: barcode,
          countedQuantity: countedQuantity,
        );

        if (!success) {
          log(
            'submitToErp: Failed to submit $productName (productId: $productId)',
          );
          skippedProducts.add('$productName (Submission failed)');
          allSuccessful = false;
        } else {
          log(
            'submitToErp: Successfully submitted $productName (productId: $productId)',
          );
        }
      }

      if (allSuccessful) {
        log('submitToErp: All sessions submitted successfully');
        return {
          'success': true,
          'message': 'Successfully submitted to ERP',
          'skippedProducts': skippedProducts,
        };
      } else {
        log('submitToErp: Some sessions failed to submit: $skippedProducts');
        return {
          'success': false,
          'message': 'Some sessions failed to submit.',
          'skippedProducts': skippedProducts,
        };
      }
    } catch (e) {
      log('submitToErp: Error submitting sessions: $e');
      return {
        'success': false,
        'message': 'Error submitting sessions: $e',
        'skippedProducts': [],
      };
    }
  }
}

// Provider for SubmitErpService
final submitErpServiceProvider = Provider<SubmitErpService>((ref) {
  return SubmitErpService(ref.read(sharedPrefsProvider.future));
});
