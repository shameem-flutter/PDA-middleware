import 'package:flutter_test/flutter_test.dart';
import 'package:pda/models/products.dart';

void main() {
  group('Product API & Serialization Tests', () {
    test('Correctly parses Django API item format', () {
      final djangoJson = {
        'item_id': 101,
        'item_name': 'Test Item Django',
        'item_code': 'DJ-101',
        'current_stock': 45,
        'sale_price': '29.99',
        'purchase_price': 15.0,
        'group': 'Retail',
        'organization': 'Org1',
      };

      final product = Product.fromApi(djangoJson);

      expect(product.id, equals(101));
      expect(product.name, equals('Test Item Django'));
      expect(product.sku, equals('DJ-101'));
      expect(product.barcode, equals('DJ-101'));
      expect(product.erpQuantity, equals(45));
      expect(product.salePrice, equals(29.99));
      expect(product.cost, equals(15.0));
      expect(product.companyName, equals('Org1'));
    });

    test('Correctly parses Odoo API item format', () {
      final odooJson = {
        'id': 202,
        'name': 'Test Item Odoo',
        'barcode': '123456789',
        'available_qty': 100,
        'product_id': 'PROD-202',
        'sale_price': 50.0,
      };

      final product = Product.fromApi(odooJson);

      expect(product.id, equals(202));
      expect(product.name, equals('Test Item Odoo'));
      expect(product.barcode, equals('123456789'));
      expect(product.erpQuantity, equals(100));
      expect(product.productId, equals('PROD-202'));
    });

    test('Converts to and from SQLite map correctly', () {
      final product = Product(
        id: 303,
        name: 'SQLite Product',
        barcode: '987654321',
        erpQuantity: 10,
        sku: 'SKU-303',
        salePrice: 19.99,
        cost: 9.99,
      );

      final map = product.toMap();
      expect(map['id'], equals(303));
      expect(map['name'], equals('SQLite Product'));
      expect(map['barcode'], equals('987654321'));

      final reconstructed = Product.fromMap(map);
      expect(reconstructed.id, equals(303));
      expect(reconstructed.name, equals('SQLite Product'));
      expect(reconstructed.barcode, equals('987654321'));
      expect(reconstructed.erpQuantity, equals(10));
      expect(reconstructed.sku, equals('SKU-303'));
    });
  });
}
