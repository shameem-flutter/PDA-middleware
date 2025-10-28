import 'dart:async';

class EventBus {
  EventBus._internal();

  static final EventBus _instance = EventBus._internal();

  factory EventBus() => _instance;

  final _tabChangeController = StreamController<int>.broadcast();
  Stream<int> get tabChangeStream => _tabChangeController.stream;
  void switchToTab(int index) {
    _tabChangeController.sink.add(index);
  }

  final _sessionChangeController = StreamController<void>.broadcast();
  Stream<void> get sessionChangeStream => _sessionChangeController.stream;
  void notifySessionChanged() {
    _sessionChangeController.sink.add(null);
  }

  final _submitPressedController = StreamController<void>.broadcast();
  Stream<void> get submitPressedStream => _submitPressedController.stream;
  void notifySubmitPressed() {
    _submitPressedController.sink.add(null);
  }

  final _productUpdateController =
      StreamController<Map<String, dynamic>>.broadcast();
  Stream<Map<String, dynamic>> get productUpdateStream =>
      _productUpdateController.stream;
  void notifyProductUpdated(int productId, int newQty) =>
      _productUpdateController.add({"id": productId, "qty": newQty});

  final _scannerRequestedController = StreamController<void>.broadcast();
  Stream<void> get scannerRequestedStream => _scannerRequestedController.stream;
  void notifyScannerRequested() => _scannerRequestedController.sink.add(null);

  void dispose() {}
}
