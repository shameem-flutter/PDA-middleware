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

  // ✅ Unified API parser that supports all Django and Odoo JSON key variants
  factory Product.fromApi(Map<String, dynamic> map) {
    final parsedId = _parseInt(map['item_id']) ??
        _parseInt(map['id']) ??
        _parseInt(map['product_id']) ??
        _parseInt(map['auto_id']);

    final parsedBarcode = _parseString(map['barcode']) ??
        _parseString(map['item_code']) ??
        _parseString(map['default_code']);

    final parsedSku = _parseString(map['sku']) ??
        parsedBarcode ??
        _parseString(map['reference']) ??
        parsedId?.toString() ??
        'NO-SKU';

    final parsedProductId = _parseString(map['product_id']) ??
        _parseString(map['item_id']) ??
        parsedId?.toString();

    return Product(
      id: parsedId,
      name: _parseString(map['name']) ??
          _parseString(map['item_name']) ??
          _parseString(map['product_name']) ??
          _parseString(map['printing_name']) ??
          'Unknown Product',
      sku: parsedSku,
      barcode: parsedBarcode,
      erpQuantity: _parseInt(map['stock_qty']) ??
          _parseInt(map['current_stock']) ??
          _parseInt(map['available_qty']) ??
          _parseInt(map['qty']) ??
          0,
      productId: parsedProductId,
      imageUrl: _parseString(map['image_url']) ?? _parseString(map['imageUrl']),
      categoryName: _parseString(map['group_name']) ??
          _parseString(map['group']) ??
          _parseString(map['category_name']) ??
          _parseString(map['category']),
      categoryId: _parseInt(map['group_id']) ?? _parseInt(map['category_id']),
      salePrice: _parseDouble(map['price']) ??
          _parseDouble(map['sale_price']) ??
          _parseDouble(map['mrp']),
      cost: _parseDouble(map['purchase_price']) ??
          _parseDouble(map['cost_price']) ??
          _parseDouble(map['cost']) ??
          _parseDouble(map['basic_rate']),
      uomName: _parseString(map['unit_name']) ??
          _parseString(map['uom']) ??
          _parseString(map['uom_name']) ??
          _parseString(map['unit']),
      reference: _parseString(map['reference']) ?? parsedBarcode,
      companyName: _parseString(map['company_name']) ??
          _parseString(map['organization']),
    );
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

  // ✅ Creates object from local SQLite data with safe camelCase & snake_case column fallbacks
  factory Product.fromMap(Map<String, dynamic> map) => Product(
    id: _parseInt(map['id']) ?? _parseInt(map['item_id']) ?? _parseInt(map['product_id']),
    name: (map['name'] ?? map['product_name'] ?? map['item_name'] ?? map['printing_name'] ?? 'Unknown').toString(),
    barcode: map['barcode']?.toString() ?? map['item_code']?.toString(),
    erpQuantity: _parseInt(map['erpQuantity']) ??
        _parseInt(map['erp_quantity']) ??
        _parseInt(map['current_stock']) ??
        _parseInt(map['available_qty']) ??
        0,
    productId: (map['product_id'] ?? map['productId'] ?? map['item_id'])?.toString(),
    imageUrl: (map['imageUrl'] ?? map['image_url'])?.toString(),
    categoryName: (map['category_name'] ?? map['categoryName'] ?? map['group'])?.toString(),
    categoryId: _parseInt(map['category_id']) ?? _parseInt(map['categoryId']),
    salePrice: _parseDouble(map['sale_price']) ??
        _parseDouble(map['salePrice']) ??
        _parseDouble(map['mrp']),
    cost: _parseDouble(map['cost']) ??
        _parseDouble(map['cost_price']) ??
        _parseDouble(map['purchase_price']),
    uomName: (map['uom_name'] ?? map['uomName'] ?? map['unit'])?.toString(),
    sku: (map['sku'] ?? map['item_code'] ?? map['default_code'] ?? map['reference'] ?? 'NO-SKU').toString(),
    reference: (map['reference'] ?? map['item_code'])?.toString(),
    companyName: (map['company_name'] ?? map['companyName'] ?? map['organization'])?.toString(),
  );

  // ✅ Converts Product to SQLite Map (only includes id if non-null to avoid SET id = NULL primary key mismatch)
  Map<String, dynamic> toMap() {
    final map = <String, dynamic>{
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
    if (id != null) {
      map['id'] = id;
    }
    return map;
  }

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

  static String? _parseString(dynamic value) {
    if (value == null) return null;
    if (value is List && value.isNotEmpty) return value.first.toString();
    final str = value.toString().trim();
    return str.isNotEmpty ? str : null;
  }
}
