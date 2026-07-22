import 'dart:developer';
import 'dart:io';
import 'package:flutter/foundation.dart';

void printOrLog(String message) {
  // Suppress all debug logging in release builds
  if (kReleaseMode) return;

  // Redact sensitive patterns if present in log strings
  String sanitizedMessage = message;
  final sensitivePatterns = [
    RegExp(r'(password[:=]\s*)[^\s,}\]]+', caseSensitive: false),
    RegExp(r'(token[:=]\s*)[^\s,}\]]+', caseSensitive: false),
    RegExp(r'(session_id[:=]\s*)[^\s,}\]]+', caseSensitive: false),
    RegExp(r'(authorization[:=]\s*)[^\s,}\]]+', caseSensitive: false),
    RegExp(r'(cookie[:=]\s*)[^\s,}\]]+', caseSensitive: false),
  ];

  for (final pattern in sensitivePatterns) {
    sanitizedMessage = sanitizedMessage.replaceAllMapped(
      pattern,
      (match) => "${match.group(1)}[REDACTED]",
    );
  }

  if (kIsWeb) {
    log(sanitizedMessage);
  } else if (Platform.isAndroid) {
    log(sanitizedMessage);
  } else {
    debugPrint(sanitizedMessage);
  }
}
