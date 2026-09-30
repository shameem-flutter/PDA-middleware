import 'package:flutter_test/flutter_test.dart';
import 'package:pda/models/products.dart';

void main() {
  group('Product API & Serialization Tests', () {
    test('Correctly parses user Django API payload format', () {
      final djangoUserJson = {
        'item_id': 4056,
        'name': '+JOSHANDA',
        'arabic_name': '#NAME?',
        'price': 1.5,
        'purchase_price': 0.35,
        'barcode': '855434002966',
        'group_id': 29,
        'group_name': 'COSMETICS & CLEANING',
        'stock_qty': -5.0,
        'unit_name': 'PCS',
        'company_id': [1],
        'company_name': ['Haitham Saud Al-Subhi- Contracting Establishment'],
      };

      final product = Product.fromApi(djangoUserJson);

      expect(product.id, equals(4056));
      expect(product.name, equals('+JOSHANDA'));
      expect(product.barcode, equals('855434002966'));
      expect(product.erpQuantity, equals(-5));
      expect(product.salePrice, equals(1.5));
      expect(product.cost, equals(0.35));
      expect(product.categoryName, equals('COSMETICS & CLEANING'));
      expect(product.uomName, equals('PCS'));
      expect(product.companyName, equals('Haitham Saud Al-Subhi- Contracting Establishment'));
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
