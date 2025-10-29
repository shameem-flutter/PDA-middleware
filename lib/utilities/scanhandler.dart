import 'dart:developer';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:pda/constants/color_constants.dart';
import 'package:pda/models/products.dart';
import 'package:pda/providers/navigation_provider.dart';
import 'package:pda/providers/providers.dart';

bool _isHandlingScan = false;
String? _lastCode;
DateTime? _lastScanTime;

Future<void> handleScannedCode(
  ScaffoldMessengerState messenger,
  String rawCode,
  WidgetRef ref,
) async {
  if (_isHandlingScan) return;
  _isHandlingScan = true;

  final code = rawCode;
  log("🔍 Scanned code: '$code' (raw: '$rawCode')");

  final now = DateTime.now();
  if (_lastCode == code &&
      _lastScanTime != null &&
      now.difference(_lastScanTime!) < const Duration(milliseconds: 300)) {
    log("🚫 Duplicate scan ignored: $code");
    _isHandlingScan = false;
    return;
  }
  _lastCode = code;
  _lastScanTime = now;

  final dbHelper = ref.read(dbProvider);
  Product? product = await dbHelper.getProductByBarcode(code);

  // Try ERP API if not found locally
  // if (product == null) {
  //   final pdaServices = ref.read(pdaServicesProvider);
  //   final response = await pdaServices.getProductByBarcode(code);
  //   if (response != null &&
  //       response.statusCode == 200 &&
  //       response.data['result'] != null) {
  //     final data = response.data['result'] as List;
  //     if (data.isNotEmpty) {
  //       product = Product.fromMap(data.first as Map<String, dynamic>);
  //       await dbHelper.insertOrUpdateProduct(product);
  //       log("✅ Fetched product from API: ${product.name} (ID: ${product.id})");
  //     }
  //   }
  // }

  if (product == null) {
    messenger.showSnackBar(
      SnackBar(
        content: Text("❌ Product not found for barcode '$code'"),
        duration: Duration(milliseconds: 800),
      ),
    );

    log("❌ No product found for barcode '$code'");
    _isHandlingScan = false;
    return;
  }

  log("✅ Found product: ${product.name} (ID: ${product.id})");
  final sessionsNotifier = ref.read(sessionsNotifierProvider.notifier);
  final existingSession = await dbHelper.getCountingSessionByProductId(
    product.id!,
  );
  int newCount = (existingSession?.countedQuantity ?? 0) + 1;
  if (existingSession != null) {
    await sessionsNotifier.updateSession(product.id!, newCount);
  } else {
    await sessionsNotifier.createSession(product.id!, newCount);
  }

  messenger.showSnackBar(
    SnackBar(
      content: Text(
        "✅ ${product.name} Count = $newCount",
        style: TextStyle(fontWeight: FontWeight.w700),
      ),
      duration: Duration(milliseconds: 800),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      backgroundColor: primaryColor,
    ),
  );

  ref.read(tabNavigationProvider).switchToReview();
  Future.delayed(const Duration(milliseconds: 200), () {
    _isHandlingScan = false;
  });
}
