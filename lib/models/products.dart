class Product {
  final int? id;
  final String name;
  final String sku;
  final String? barcode;
  final int erpQuantity;
  final String? imageUrl;
  final String? categoryName;
  final int? categoryId;
  final double? salePrice;
  final int? cost;
  final String? uomName;
  final String? reference;
  final int? productId;
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

  // ✅ fromMap: Used when reading from API (uses 'available_qty')
  factory Product.fromMap(Map<String, dynamic> map) {
    return Product(
      id: map['id'] as int? ?? map['product_id'] as int?,
      name:
          map['name'] as String? ?? map['product_name'] as String? ?? 'Unknown',
      sku:
          map['default_code'] as String? ??
          map['reference'] as String? ??
          map['id']?.toString() ??
          '',
      barcode: map['barcode'] as String?,
      erpQuantity: (map['available_qty'] as num?)?.toInt() ?? 0, // ✅ From API
      imageUrl: map['image_url'] as String?,
      categoryName: map['category_name'] as String?,
      categoryId: map['category_id'] as int?,
      salePrice: double.tryParse(map['sale_price']?.toString() ?? ''),
      cost: (map['cost'] as num?)?.toInt(),
      uomName: map['uom_name'] as String?,
      reference: map['reference'] as String?,
      productId: map['product_id'] as int?,
      companyName: map['company_name'] as String?,
    );
  }

  // ✅ toMap: Used when writing to database (uses 'erpQuantity')
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'sku': sku,
      'barcode': barcode,
      'erpQuantity': erpQuantity, // ✅ For database column
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
