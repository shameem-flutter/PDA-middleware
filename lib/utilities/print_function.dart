import 'dart:developer';
import 'dart:io';
import 'package:flutter/foundation.dart';

void printOrLog(String message) {
  if (kIsWeb) {
    log(message);
  } else if (Platform.isAndroid) {
    log(message);
  } else {
    debugPrint(message);
  }
}
