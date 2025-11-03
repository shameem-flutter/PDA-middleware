import 'dart:convert';

/// Parse and serialize the full API model
PdaServiceModel pdaServiceModelFromJson(String str) =>
    PdaServiceModel.fromJson(json.decode(str));

String pdaServiceModelToJson(PdaServiceModel data) =>
    json.encode(data.toJson());

/// Root Model (unified for both Django and Odoo)
class PdaServiceModel {
  final String? jsonrpc; // ✅ For Odoo
  final dynamic id;
  final int? statusCode; // ✅ For Django
  final String? title;
  final List<Result> result;
  final dynamic errors;
  final String? message;

  PdaServiceModel({
    this.jsonrpc,
    this.id,
    this.statusCode,
    this.title,
    required this.result,
    this.errors,
    this.message,
  });

  /// ✅ Handles both Django and Odoo responses automatically
  factory PdaServiceModel.fromJson(Map<String, dynamic> json) {
    final isOdoo = json.containsKey("jsonrpc");

    return PdaServiceModel(
      jsonrpc: json["jsonrpc"],
      id: json["id"],
      statusCode: json["statuscode"],
      title: json["title"],
      result: List<Result>.from(
        (isOdoo ? json["result"] ?? [] : json["data"] ?? json["result"] ?? [])
            .map((x) => Result.fromUnified(x)),
      ),
      errors: json["errors"],
      message: json["message"],
    );
  }

  Map<String, dynamic> toJson() => {
    "jsonrpc": jsonrpc,
    "id": id,
    "statuscode": statusCode,
    "title": title,
    "data": List<dynamic>.from(result.map((x) => x.toJson())),
    "errors": errors,
    "message": message,
  };
}

/// ✅ Unified Result model for Odoo, Django, and SQLite
class Result {
  final dynamic id;
  final String name;
  final String sku;
  final String? barcode;
  final int erpQuantity;
  final dynamic productId;
  final String? imageUrl;
  final String? categoryName;
  final int? categoryId;
  final double? salePrice;
  final double? cost;
  final double? tax;
  final String? uomName;
  final int? uomId;
  final String? reference;
  final String? companyName;
  final String? companyId;

  Result({
    this.id,
    required this.name,
    required this.sku,
    this.barcode,
    this.erpQuantity = 0,
    this.productId,
    this.imageUrl,
    this.categoryName,
    this.categoryId,
    this.salePrice,
    this.cost,
    this.tax,
    this.uomName,
    this.uomId,
    this.reference,
    this.companyName,
    this.companyId,
  });

  static String? _safeString(dynamic value) {
    if (value == null) return null;
    if (value is String) return value;
    return value.toString();
  }

  /// ✅ Handles Odoo, Django, and local SQLite formats
  factory Result.fromUnified(Map<String, dynamic> map) {
    // Detect which backend it came from
    final isOdoo =
        map.containsKey("available_qty") || map.containsKey("product_id");
    final isDjango =
        map.containsKey("item_code") && map.containsKey("item_name");

    if (isOdoo) {
      // 🔹 Odoo format
      return Result(
        id: _toInt(map['id']) ?? _toInt(map['product_id']),
        name: map['product_name'] ?? map['name'] ?? 'Unknown',
        sku:
            map['default_code'] ??
            map['reference'] ??
            map['barcode'] ??
            'NO-SKU',
        barcode: map['barcode'] as String?,
        erpQuantity: _toInt(map['available_qty']) ?? 0,
        productId: map['product_id'],
        imageUrl: map['image_url'] as String?,
        categoryName: map['category_name'] as String?,
        categoryId: _toInt(map['category_id']),
        salePrice: _toDouble(map['sale_price']),
        cost: _toDouble(map['cost']),
        tax: _toDouble(map['tax']),
        uomName: map['uom_name'] as String?,
        uomId: _toInt(map['uom_id']),
        reference: map['reference'] as String?,
        companyName: map['company_name'] as String?,
        companyId: _safeString(map['company_id']),
      );
    } else if (isDjango) {
      // 🔹 Django format
      return Result(
        id: _toInt(map['item_id']) ?? _toInt(map['auto_id']),
        name: map['item_name'] ?? map['printing_name'] ?? 'Unknown Product',
        sku: map['item_code'] ?? 'NO-SKU',
        barcode: map['item_code'],
        erpQuantity: _toInt(map['current_stock']) ?? 0,
        productId: map['item_id'],
        salePrice: _toDouble(map['sale_price']) ?? _toDouble(map['mrp']),
        cost:
            _toDouble(map['purchase_price']) ??
            _toDouble(map['cost_price']) ??
            _toDouble(map['basic_rate']),
        tax:
            _toDouble(map['gst_tax_percentage']) ??
            _toDouble(map['tax_percentage']),
        uomName: map['unit']?.toString(),
        categoryName: map['group']?.toString(),
        categoryId: null,
        reference: map['item_code'],
        companyName: map['organization']?.toString(),
        imageUrl: map['image_url']?.toString(),
      );
    } else {
      // 🔹 Local SQLite or unknown fallback
      return Result(
        id: _toInt(map['id']),
        name: map['name'] ?? 'Unknown Product',
        sku: map['sku'] ?? 'NO-SKU',
        barcode: map['barcode'] as String?,
        erpQuantity: _toInt(map['erpQuantity']) ?? 0,
        productId: map['product_id'],
        imageUrl: map['imageUrl'] ?? map['image_url'],
        categoryName: map['category_name'] as String?,
        categoryId: _toInt(map['category_id']),
        salePrice: _toDouble(map['sale_price']),
        cost: _toDouble(map['cost']),
        tax: _toDouble(map['tax']),
        uomName: map['uom_name'] as String?,
        reference: map['reference'] as String?,
        companyName: map['company_name'] as String?,
        companyId: _safeString(map['company_id']),
      );
    }
  }

  // ✅ Add helper to safely convert to int
  static int? _toInt(dynamic value) {
    if (value == null) return null;
    if (value is int) return value;
    if (value is String) return int.tryParse(value);
    if (value is num) return value.toInt();
    return null;
  }

  static double? _toDouble(dynamic value) {
    if (value == null) return null;
    if (value is num) return value.toDouble();
    return double.tryParse(value.toString());
  }

  Map<String, dynamic> toJson() => {
    "id": id,
    "name": name,
    "sku": sku,
    "barcode": barcode,
    "erpQuantity": erpQuantity,
    "product_id": productId,
    "image_url": imageUrl,
    "category_name": categoryName,
    "category_id": categoryId,
    "sale_price": salePrice,
    "cost": cost,
    "tax": tax,
    "uom_name": uomName,
    "uom_id": uomId,
    "reference": reference,
    "company_name": companyName,
    "company_id": companyId,
  };

  Result copyWith({
    int? id,
    String? name,
    String? sku,
    String? barcode,
    int? erpQuantity,
    String? productId,
    String? imageUrl,
    String? categoryName,
    int? categoryId,
    double? salePrice,
    double? cost,
    double? tax,
    String? uomName,
    int? uomId,
    String? reference,
    String? companyName,
    String? companyId,
  }) {
    return Result(
      id: id ?? this.id,
      name: name ?? this.name,
      sku: sku ?? this.sku,
      barcode: barcode ?? this.barcode,
      erpQuantity: erpQuantity ?? this.erpQuantity,
      productId: productId ?? this.productId,
      imageUrl: imageUrl ?? this.imageUrl,
      categoryName: categoryName ?? this.categoryName,
      categoryId: categoryId ?? this.categoryId,
      salePrice: salePrice ?? this.salePrice,
      cost: cost ?? this.cost,
      tax: tax ?? this.tax,
      uomName: uomName ?? this.uomName,
      uomId: uomId ?? this.uomId,
      reference: reference ?? this.reference,
      companyName: companyName ?? this.companyName,
      companyId: companyId ?? this.companyId,
    );
  }
}
