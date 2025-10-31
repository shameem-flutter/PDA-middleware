import 'dart:developer';
import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:pda/constants/apiclient.dart';
import 'package:pda/providers/providers.dart';
import 'package:pda/services/api_services/authservice.dart';
import 'package:pda/services/api_services/base_api_service.dart';
import 'package:shared_preferences/shared_preferences.dart';

class SubmitErpService {
  final BaseApiServices _api;
  final Authservice _authservice;
  SubmitErpService(Future<SharedPreferences> prefs, this._authservice)
    : _api = BaseApiServices(prefs: prefs, dio: ApiClient.dio);

  Future<bool> createStockAdjustment({
    required int itemCode,
    required int countedQuantity,
    required int erpQuantity,
  }) async {
    final String? token = await _authservice.getDjangoToken();
    if (token == null) {
      log("❌ No Django token found. User might not be logged in.");
      return false;
    }

    final String baseUrl =
        "http://middleware.febnohost.com/api/v1/waslasoft_retail/items/$itemCode/";
    final queryParams = {"organization_id": "WASL6A81F8A9"};

    final data = {"current_stock": countedQuantity + erpQuantity};

    try {
      final response = await _api.dio.patch(
        baseUrl,
        data: data,
        options: Options(
          headers: {
            "Authorization": "Token $token",
            "Content-Type": "application/json",
            "Accept": "application/json",
          },
        ),
        queryParameters: queryParams,
      );

      final success = response.statusCode == 200;
      if (success) {
        log("✅ Stock updated successfully for itemCode: $itemCode");
      } else {
        log(
          "⚠️ Failed for $itemCode | Status: ${response.statusCode}, Data: ${response.data}",
        );
      }
      return success;
    } on DioException catch (e) {
      log(
        "❌ DioException updating item $itemCode: ${e.response?.statusCode} - ${e.response?.data}",
      );
      return false;
    } catch (e) {
      log("❌ Unexpected error updating item $itemCode: $e");
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
        final itemCode = session['itemCode'] ?? session['productId'];
        if (itemCode is! int) {
          log('submitToErp: Invalid or missing itemCode for session: $session');
          skippedProducts.add(
            '${session['productName']} (Missing or invalid itemCode)',
          );
          allSuccessful = false;
          continue;
        }

        final countedQuantity = session['countedQuantity'] as int? ?? 0;
        final erpQuantity = session['erpQuantity'] as int? ?? 0;

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

        // if (itemCode == null) {
        //   log('submitToErp: Skipping session, missing itemcode for $itemCode');
        //   skippedProducts.add('$itemCode (Missing itemcode)');
        //   allSuccessful = false;
        //   continue;
        // }

        if (barcode == null || barcode.isEmpty) {
          log(
            'submitToErp: Invalid barcode for $itemCode (productId: $itemCode), barcode: $barcode, session keys: ${session.keys}',
          );
          barcode = 'UNKNOWN_$itemCode';
          log('submitToErp: Using fallback barcode: $barcode');
          skippedProducts.add('$itemCode (Invalid barcode, used $barcode)');
          // Proceed with fallback barcode
        }

        log(
          'submitToErp: Submitting $itemCode (productId: $itemCode, barcode: $barcode, quantity: $countedQuantity)',
        );
        final success = await createStockAdjustment(
          itemCode: itemCode,
          countedQuantity: countedQuantity,
          erpQuantity: erpQuantity,
        );

        if (!success) {
          log('submitToErp: Failed to submit $itemCode (productId: $itemCode)');
          skippedProducts.add('$itemCode (Submission failed)');
          allSuccessful = false;
        } else {
          log(
            'submitToErp: Successfully submitted $itemCode (productId: $itemCode)',
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
  return SubmitErpService(
    ref.read(sharedPrefsProvider.future),
    ref.read(authServiceProvider),
  );
});
