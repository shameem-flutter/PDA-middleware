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
    required this.sku,
    this.barcode,
    this.erpQuantity = 0,
    this.imageUrl,
    this.categoryName,
    this.categoryId,
    this.salePrice,
    this.cost,
    this.uomName,
    this.reference,
    this.productId,
    this.companyName,
  });

  // ✅ For reading from API (uses API field names)
  factory Product.fromApiMap(Map<String, dynamic> map) {
    return Product(
      id: map['item_id'] as int?,
      name: map['item_name'] as String? ?? 'Unknown Product',
      barcode: map['item_code'] as String?,
      erpQuantity: (map['current_stock'] as num?)?.toInt() ?? 0,
      productId: map['id']?.toString(), // API returns UUID string
      sku:
          map['default_code'] as String? ??
          map['reference'] as String? ??
          map['item_code'] as String? ??
          map['id']?.toString() ??
          'NO-SKU',
      imageUrl: map['image_url'] as String?,
      categoryName: map['category_name'] as String?,
      categoryId: map['category_id'] as int?,
      salePrice: map['sale_price'] != null
          ? (map['sale_price'] as num).toDouble()
          : null,
      cost: (map['cost'] as num?)?.toDouble(),
      uomName: map['uom_name'] as String?,
      reference: map['reference'] as String?,
      companyName: map['company_name'] as String?,
    );
  }

  // ✅ For reading from Database (uses database column names)
  factory Product.fromMap(Map<String, dynamic> map) {
    // Helper to safely convert to string
    String? safeString(dynamic value) {
      if (value == null) return null;
      if (value is String) return value;
      if (value is int) return value.toString();
      return value.toString();
    }

    return Product(
      id: map['id'] as int?,
      name: map['name'] as String? ?? 'Unknown Product',
      barcode: map['barcode'] as String?,
      erpQuantity: (map['erpQuantity'] as num?)?.toInt() ?? 0,
      productId: safeString(map['product_id']), // ✅ Handle both int and String
      sku: map['sku'] as String? ?? 'NO-SKU',
      imageUrl: map['imageUrl'] as String?,
      categoryName: map['category_name'] as String?,
      categoryId: map['category_id'] as int?,
      salePrice: map['sale_price'] != null
          ? (map['sale_price'] as num).toDouble()
          : null,
      cost: map['cost'] != null ? (map['cost'] as num).toDouble() : null,
      uomName: map['uom_name'] as String?,
      reference: map['reference'] as String?,
      companyName: map['company_name'] as String?,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'sku': sku,
      'barcode': barcode,
      'erpQuantity': erpQuantity,
      'imageUrl': imageUrl,
      'category_name': categoryName,
      'category_id': categoryId,
      'sale_price': salePrice,
      'cost': cost,
      'uom_name': uomName,
      'reference': reference,
      'product_id': productId,
      'company_name': companyName,
    };
  }
}
