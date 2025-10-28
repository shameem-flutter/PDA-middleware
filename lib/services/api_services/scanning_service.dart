import 'dart:async';
import 'package:flutter/services.dart';

class ScannerService {
  static const EventChannel _channel = EventChannel(
    'com.example.pda/scanner_events',
  );

  static final ScannerService _instance = ScannerService._internal();
  factory ScannerService() => _instance;

  final StreamController<String> _scanStreamController =
      StreamController<String>.broadcast();
  StreamSubscription<dynamic>? _eventSubscription;

  ScannerService._internal() {
    _eventSubscription = _channel.receiveBroadcastStream().listen(
      (event) {
        final code = event?.toString();
        if (code != null && code.isNotEmpty) {
          _scanStreamController.add(code);
        }
      },
      onError: (error) {
        _scanStreamController.addError(error);
      },
      onDone: () {
        _scanStreamController.close();
      },
    );
  }

  Stream<String> get scanStream => _scanStreamController.stream;

  void dispose() {
    _eventSubscription?.cancel();
    _scanStreamController.close();
  }
}
