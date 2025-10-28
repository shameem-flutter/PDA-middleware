import 'package:pda/models/pda_service_model.dart';
import 'package:pda/models/products.dart';

extension ResultMapper on Result {
  Product toLocalProduct() {
    return Product(
      id: productId,
      name: productName,
      barcode: barcode,
      sku: reference ?? '',
      erpQuantity: availableQty?.toInt() ?? 0,
      imageUrl: null,
      categoryId: categoryId,
      categoryName: categoryName,
      salePrice: salePrice?.toDouble(),
      cost: cost?.toInt(),
      uomName: uomName?.toString(),
      reference: reference,
      productId: productId,
      companyName: companyName?.toString() ?? "TEST COMPANY",
    );
  }
}
