import 'package:pda/models/pda_service_model.dart';
import 'package:pda/models/products.dart';

extension ResultMapper on Result {
  Product toLocalProduct() {
    // Detect which system the product came from
    final bool isOdoo =
        productId != null &&
        name != 'Unknown' &&
        sku != 'NO-SKU' &&
        barcode != null;
    final bool isDjango = !isOdoo && id != null;

    if (isOdoo) {
      // 🔹 Odoo mapping
      return Product(
        id: _parseInt(productId),
        name: name,
        barcode: barcode,
        sku: reference ?? sku,
        erpQuantity: erpQuantity,
        imageUrl: imageUrl,
        categoryId: categoryId,
        categoryName: categoryName,
        salePrice: salePrice,
        cost: cost,
        uomName: uomName,
        reference: reference,
        productId: productId,
        companyName: companyName ?? "TEST COMPANY",
      );
    } else if (isDjango) {
      // 🔹 Django mapping
      return Product(
        id: _parseInt(id),
        name: name,
        barcode: barcode ?? sku,
        sku: sku,
        erpQuantity: erpQuantity,
        imageUrl: imageUrl,
        categoryId: categoryId,
        categoryName: categoryName,
        salePrice: salePrice,
        cost: cost,
        reference: reference,
        productId: productId ?? id,
        companyName: companyName ?? "TEST COMPANY",
      );
    } else {
      // 🔹 Fallback mapping
      return Product(
        id: _parseInt(id),
        name: name.isNotEmpty ? name : "Unknown Product",
        sku: sku.isNotEmpty ? sku : "NO-SKU",
        erpQuantity: erpQuantity,
        productId: productId,
        companyName: companyName ?? "TEST COMPANY",
      );
    }
  }

  int? _parseInt(dynamic value) {
    if (value == null) return null;
    if (value is int) return value;
    if (value is String) return int.tryParse(value);
    if (value is num) return value.toInt();
    return null;
  }
}
