//     final pdaServiceModel = pdaServiceModelFromJson(jsonString);

import 'dart:convert';

PdaServiceModel pdaServiceModelFromJson(String str) =>
    PdaServiceModel.fromJson(json.decode(str));

String pdaServiceModelToJson(PdaServiceModel data) =>
    json.encode(data.toJson());

class PdaServiceModel {
  String jsonrpc;
  dynamic id;
  List<Result> result;

  PdaServiceModel({
    required this.jsonrpc,
    required this.id,
    required this.result,
  });

  factory PdaServiceModel.fromJson(Map<String, dynamic> json) =>
      PdaServiceModel(
        jsonrpc: json["jsonrpc"],
        id: json["id"],
        result: List<Result>.from(
          json["result"].map((x) => Result.fromJson(x)),
        ),
      );

  Map<String, dynamic> toJson() => {
    "jsonrpc": jsonrpc,
    "id": id,
    "result": List<dynamic>.from(result.map((x) => x.toJson())),
  };
}

class Result {
  String productName;
  int productId;
  String barcode;
  String? reference;
  UomName? uomName;
  int? uomId;
  String? categoryName;
  int? categoryId;
  double? availableQty;
  double? salePrice;
  double? cost;
  double? tax;
  String? companyName;
  String? companyId;

  Result({
    required this.productName,
    required this.productId,
    required this.barcode,
    this.reference,
    this.uomName,
    this.uomId,
    this.categoryName,
    this.categoryId,
    this.availableQty,
    this.salePrice,
    this.cost,
    this.tax,
    this.companyName,
    this.companyId,
  });

  factory Result.fromJson(Map<String, dynamic> json) => Result(
    productName: json["product_name"] ?? "",
    productId: (json["product_id"] as num).toInt(),
    barcode: json["barcode"] ?? "",
    reference: json["reference"],
    uomName: json["uom_name"] != null
        ? uomNameValues.map[json["uom_name"]]
        : null,
    uomId: json["uom_id"] != null ? (json["uom_id"] as num).toInt() : null,
    categoryName: json["category_name"],
    categoryId: json["category_id"] != null
        ? (json["category_id"] as num).toInt()
        : null,
    availableQty: json["available_qty"] != null
        ? (json["available_qty"] as num).toDouble()
        : null,
    salePrice: json["sale_price"] != null
        ? (json["sale_price"] as num).toDouble()
        : null,
    cost: json["cost"] != null ? (json["cost"] as num).toDouble() : null,
    tax: json["tax"] != null ? (json["tax"] as num).toDouble() : null,
    companyName: json["company_name"],
    companyId: json["company_id"]?.toString(),
  );

  Map<String, dynamic> toJson() => {
    "product_name": productName,
    "product_id": productId,
    "barcode": barcode,
    "reference": reference,
    "uom_name": uomName != null ? uomNameValues.reverse[uomName] : null,
    "uom_id": uomId,
    "category_name": categoryName,
    "category_id": categoryId,
    "available_qty": availableQty,
    "sale_price": salePrice,
    "cost": cost,
    "tax": tax,
    "company_name": companyName,
    "company_id": companyId,
  };
}

enum UomName {
  BOX,
  BOX_OF_12,
  BOX_OF_36,
  G,
  PCS,
  PCS_OF_10,
  PCS_OF_24,
  PCS_OF_3,
  PCS_OF_4,
  PCS_OF_5,
  PKG,
  PKG_OF_10,
  PKG_OF_12,
  PKG_OF_16,
  PKG_OF_2,
  PKG_OF_20,
  PKG_OF_3,
  PKG_OF_4,
  PKG_OF_5,
  PKG_OF_55,
  PKG_OF_6,
  PKG_OF_7,
  UNITS,
}

final uomNameValues = EnumValues({
  "BOX": UomName.BOX,
  "BOX of 12": UomName.BOX_OF_12,
  "BOX of 36": UomName.BOX_OF_36,
  "g": UomName.G,
  "PCS": UomName.PCS,
  "PCS of 10": UomName.PCS_OF_10,
  "PCS of 24": UomName.PCS_OF_24,
  "PCS of 3": UomName.PCS_OF_3,
  "PCS of 4": UomName.PCS_OF_4,
  "PCS of 5": UomName.PCS_OF_5,
  "PKG": UomName.PKG,
  "PKG of 10": UomName.PKG_OF_10,
  "PKG of 12": UomName.PKG_OF_12,
  "PKG of 16": UomName.PKG_OF_16,
  "PKG of 2": UomName.PKG_OF_2,
  "PKG of 20": UomName.PKG_OF_20,
  "PKG of 3": UomName.PKG_OF_3,
  "PKG of 4": UomName.PKG_OF_4,
  "PKG of 5": UomName.PKG_OF_5,
  "PKG of 55": UomName.PKG_OF_55,
  "PKG of 6": UomName.PKG_OF_6,
  "PKG of 7": UomName.PKG_OF_7,
  "Units": UomName.UNITS,
});

class EnumValues<T> {
  Map<String, T> map;
  late Map<T, String> reverseMap;

  EnumValues(this.map);

  Map<T, String> get reverse {
    reverseMap = map.map((k, v) => MapEntry(v, k));
    return reverseMap;
  }
}
