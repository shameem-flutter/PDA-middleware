import 'package:flutter_test/flutter_test.dart';
import 'package:pda/models/count_session.dart';

void main() {
  group('CountingSession Unit Tests', () {
    test('Serializes to map and deserializes from map correctly', () {
      final session = CountingSession(
        id: 1,
        productId: 55,
        countedQuantity: 12,
        productName: 'Sample Item',
        erpQuantity: 20,
        status: 'pending',
      );

      final map = session.toMap();
      expect(map['id'], equals(1));
      expect(map['productId'], equals(55));
      expect(map['countedQuantity'], equals(12));
      expect(map['productName'], equals('Sample Item'));
      expect(map['erpQuantity'], equals(20));

      final restored = CountingSession.fromMap(map);
      expect(restored.id, equals(1));
      expect(restored.productId, equals(55));
      expect(restored.countedQuantity, equals(12));
      expect(restored.productName, equals('Sample Item'));
      expect(restored.erpQuantity, equals(20));
    });

    test('copyWith produces updated instance', () {
      final session = CountingSession(
        id: 1,
        productId: 55,
        countedQuantity: 5,
      );

      final updated = session.copyWith(countedQuantity: 15);
      expect(updated.id, equals(1));
      expect(updated.productId, equals(55));
      expect(updated.countedQuantity, equals(15));
    });
  });
}
