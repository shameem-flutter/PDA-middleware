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

  try {
    final code = rawCode;
    log("🔍 Scanned code: '$code' (raw: '$rawCode')");

    final now = DateTime.now();
    if (_lastCode == code &&
        _lastScanTime != null &&
        now.difference(_lastScanTime!) < const Duration(milliseconds: 300)) {
      log("🚫 Duplicate scan ignored: $code");
      return;
    }
    _lastCode = code;
    _lastScanTime = now;

    final dbHelper = ref.read(dbProvider);
    Product? product = await dbHelper.getProductByBarcode(code);

    if (product == null) {
      messenger.showSnackBar(
        SnackBar(
          content: Text("❌ Product not found for barcode '$code'"),
          duration: Duration(milliseconds: 800),
        ),
      );

      log("❌ No product found for barcode '$code'");
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
  } finally {
    Future.delayed(const Duration(milliseconds: 200), () {
      _isHandlingScan = false;
    });
  }
}
