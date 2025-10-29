import 'package:pda/models/pda_service_model.dart';
import 'package:pda/models/products.dart';

extension ResultMapper on Result {
  Product toLocalProduct() {
    return Product(
      id: itemId,
      name: itemName,
      barcode: itemCode,
      sku: id.toString(),
      erpQuantity: currentStock.toInt(),
      imageUrl: null,
      categoryId: autoId,
      categoryName: printingName,
      salePrice: salePrice.toDouble(),
      cost: salePrice.toDouble(),
      uomName: unit?.toString(),
      reference: "",
      productId: id.toString(),
      companyName: "TEST COMPANY",
    );
  }
}
