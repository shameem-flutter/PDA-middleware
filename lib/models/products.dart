// product.dart
import 'dart:convert';

Product productFromJson(String str) => Product.fromApi(json.decode(str));
String productToJson(Product data) => json.encode(data.toJson());

class Product {
  final int? id;
  final String name;
  final String? barcode;
  final int erpQuantity;
  final String? productId;
  final String? imageUrl;
  final String? categoryName;
  final int? categoryId;
  final double? salePrice;
  final double? cost;
  final String? uomName;
  final String sku;
  final String? reference;
  final String? companyName;

  Product({
    this.id,
    required this.name,
    this.barcode,
    required this.erpQuantity,
    this.productId,
    this.imageUrl,
    this.categoryName,
    this.categoryId,
    this.salePrice,
    this.cost,
    this.uomName,
    required this.sku,
    this.reference,
    this.companyName,
  });

  // ✅ Detects whether it's from Django or Odoo and maps automatically
  factory Product.fromApi(Map<String, dynamic> map) {
    final isDjango =
        map.containsKey('item_code') || map.containsKey('item_name');

    if (isDjango) {
      // 🔹 Django API format
      return Product(
        id: _parseInt(map['item_id']) ?? _parseInt(map['auto_id']),
        name: map['item_name'] ?? map['printing_name'] ?? 'Unknown Product',
        sku: map['item_code'] ?? 'NO-SKU',
        barcode: map['item_code'],
        erpQuantity: _parseInt(map['current_stock']) ?? 0,
        productId: map['item_id']?.toString(),
        imageUrl: map['image_url'],
        categoryName: map['group']?.toString(),
        categoryId: null,
        salePrice: _parseDouble(map['sale_price']) ?? _parseDouble(map['mrp']),
        cost:
            _parseDouble(map['purchase_price']) ??
            _parseDouble(map['cost_price']) ??
            _parseDouble(map['basic_rate']),
        uomName: map['unit']?.toString(),
        reference: map['item_code'],
        companyName: map['organization']?.toString(),
      );
    } else {
      // 🔹 Odoo API format
      return Product(
        id: _parseInt(map['id']) ?? _parseInt(map['product_id']),
        name:
            map['name'] as String? ??
            map['product_name'] as String? ??
            'Unknown',
        sku:
            map['default_code'] as String? ??
            map['reference'] as String? ??
            map['id']?.toString() ??
            'NO-SKU',
        barcode: map['barcode'] as String?,
        erpQuantity: _parseInt(map['available_qty']) ?? 0,
        productId: map['product_id']?.toString(),
        imageUrl: map['image_url'] as String?,
        categoryName: map['category_name'] as String?,
        categoryId: _parseInt(map['category_id']),
        salePrice: _parseDouble(map['sale_price']),
        cost: _parseDouble(map['cost']),
        uomName: map['uom_name'] as String?,
        reference: map['reference'] as String?,
        companyName: map['company_name'] as String?,
      );
    }
  }

  // ✅ Converts to JSON (for local DB or API storage)
  Map<String, dynamic> toJson() => {
    'id': id,
    'name': name,
    'barcode': barcode,
    'erpQuantity': erpQuantity,
    'productId': productId,
    'imageUrl': imageUrl,
    'categoryName': categoryName,
    'categoryId': categoryId,
    'salePrice': salePrice,
    'cost': cost,
    'uomName': uomName,
    'sku': sku,
    'reference': reference,
    'companyName': companyName,
  };

  // ✅ Creates object from local SQLite data
  factory Product.fromMap(Map<String, dynamic> map) => Product(
    id: _parseInt(map['id']),
    name: map['name'] ?? 'Unknown',
    barcode: map['barcode'],
    erpQuantity: _parseInt(map['erpQuantity']) ?? 0,
    productId: map['productId']?.toString(),
    imageUrl: map['imageUrl'],
    categoryName: map['categoryName'],
    categoryId: _parseInt(map['categoryId']),
    salePrice: _parseDouble(map['salePrice']),
    cost: _parseDouble(map['cost']),
    uomName: map['uomName'],
    sku: map['sku'] ?? 'NO-SKU',
    reference: map['reference'],
    companyName: map['companyName'],
  );

  // ✅ Converts Product to SQLite Map
  Map<String, dynamic> toMap() => {
    'id': id,
    'name': name,
    'barcode': barcode,
    'erpQuantity': erpQuantity,
    'product_id': productId,
    'imageUrl': imageUrl,
    'category_name': categoryName,
    'category_id': categoryId,
    'sale_price': salePrice,
    'cost': cost,
    'uom_name': uomName,
    'sku': sku,
    'reference': reference,
    'company_name': companyName,
  };

  // ✅ Helpers to parse safely
  static int? _parseInt(dynamic value) {
    if (value == null) return null;
    if (value is int) return value;
    if (value is double) return value.toInt();
    if (value is String) return int.tryParse(value);
    return null;
  }

  static double? _parseDouble(dynamic value) {
    if (value == null) return null;
    if (value is double) return value;
    if (value is int) return value.toDouble();
    if (value is String) return double.tryParse(value);
    return null;
  }
}
