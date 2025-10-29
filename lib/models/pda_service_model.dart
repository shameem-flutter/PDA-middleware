// To parse this JSON data, do
//
//     final pdaServiceModel = pdaServiceModelFromJson(jsonString);

import 'dart:convert';

PdaServiceModel pdaServiceModelFromJson(String str) =>
    PdaServiceModel.fromJson(json.decode(str));

String pdaServiceModelToJson(PdaServiceModel data) =>
    json.encode(data.toJson());

class PdaServiceModel {
  int statuscode;
  String title;
  List<Result> result;
  dynamic errors;
  String message;

  PdaServiceModel({
    required this.statuscode,
    required this.title,
    required this.result,
    required this.errors,
    required this.message,
  });

  factory PdaServiceModel.fromJson(Map<String, dynamic> json) =>
      PdaServiceModel(
        statuscode: json["statuscode"],
        title: json["title"],
        result: List<Result>.from(json["data"].map((x) => Result.fromJson(x))),
        errors: json["errors"],
        message: json["message"],
      );

  Map<String, dynamic> toJson() => {
    "statuscode": statuscode,
    "title": title,
    "data": List<dynamic>.from(result.map((x) => x.toJson())),
    "errors": errors,
    "message": message,
  };
}

class Result {
  String id;
  int autoId;
  bool isDeleted;
  dynamic customOrder;
  dynamic altTxt;
  String organization;
  int itemId;
  dynamic group;
  String itemCode;
  String itemName;
  String printingName;
  String lastItemNo;
  String hsnCode;
  int mrp;
  int wholesalePrice;
  dynamic specialPrice;
  double salePrice;
  bool lockedPrice;
  int purchasePrice;
  int? averagePurchasePrice;
  int currentStock;
  int reorderLevel;
  String remarks;
  dynamic brand;
  String? unit;
  String taxId;
  String openingStock;
  String enteredBy;
  DateTime entryDate;
  dynamic subgroup;
  String masterItemId;
  String conversionQty;
  dynamic documentId;
  bool flgdeleted;
  dynamic openingStockPurchaseRate;
  String taxPercentage;
  String basicRate;
  bool flgWeighingScaleItem;
  String costPrice;
  String keralaFoodCessPercentage;
  int gstTaxPercentage;
  double cgstTaxPercentage;
  double sgstTaxPercentage;
  int igstTaxPercentage;
  String itemNameArabic;
  String itemidx;

  Result({
    required this.id,
    required this.autoId,
    required this.isDeleted,
    required this.customOrder,
    required this.altTxt,
    required this.organization,
    required this.itemId,
    required this.group,
    required this.itemCode,
    required this.itemName,
    required this.printingName,
    required this.lastItemNo,
    required this.hsnCode,
    required this.mrp,
    required this.wholesalePrice,
    required this.specialPrice,
    required this.salePrice,
    required this.lockedPrice,
    required this.purchasePrice,
    required this.averagePurchasePrice,
    required this.currentStock,
    required this.reorderLevel,
    required this.remarks,
    required this.brand,
    required this.unit,
    required this.taxId,
    required this.openingStock,
    required this.enteredBy,
    required this.entryDate,
    required this.subgroup,
    required this.masterItemId,
    required this.conversionQty,
    required this.documentId,
    required this.flgdeleted,
    required this.openingStockPurchaseRate,
    required this.taxPercentage,
    required this.basicRate,
    required this.flgWeighingScaleItem,
    required this.costPrice,
    required this.keralaFoodCessPercentage,
    required this.gstTaxPercentage,
    required this.cgstTaxPercentage,
    required this.sgstTaxPercentage,
    required this.igstTaxPercentage,
    required this.itemNameArabic,
    required this.itemidx,
  });

  factory Result.fromJson(Map<String, dynamic> json) => Result(
    id: json["id"],
    autoId: json["auto_id"],
    isDeleted: json["is_deleted"],
    customOrder: json["custom_order"],
    altTxt: json["alt_txt"],
    organization: json["organization"],
    itemId: json["item_id"],
    group: json["group"],
    itemCode: json["item_code"],
    itemName: json["item_name"],
    printingName: json["printing_name"],
    lastItemNo: json["last_item_no"],
    hsnCode: json["hsn_code"],
    mrp: json["mrp"],
    wholesalePrice: json["wholesale_price"],
    specialPrice: json["special_price"],
    salePrice: json["sale_price"],
    lockedPrice: json["locked_price"],
    purchasePrice: json["purchase_price"],
    averagePurchasePrice: json["average_purchase_price"],
    currentStock: json["current_stock"],
    reorderLevel: json["reorder_level"],
    remarks: json["remarks"],
    brand: json["brand"],
    unit: json["unit"],
    taxId: json["tax_id"],
    openingStock: json["opening_stock"],
    enteredBy: json["entered_by"],
    entryDate: DateTime.parse(json["entry_date"]),
    subgroup: json["subgroup"],
    masterItemId: json["master_item_id"],
    conversionQty: json["conversion_qty"],
    documentId: json["document_id"],
    flgdeleted: json["flgdeleted"],
    openingStockPurchaseRate: json["opening_stock_purchase_rate"],
    taxPercentage: json["tax_percentage"],
    basicRate: json["basic_rate"],
    flgWeighingScaleItem: json["flg_weighing_scale_item"],
    costPrice: json["cost_price"],
    keralaFoodCessPercentage: json["kerala_food_cess_percentage"],
    gstTaxPercentage: json["gst_tax_percentage"],
    cgstTaxPercentage: json["cgst_tax_percentage"]?.toDouble(),
    sgstTaxPercentage: json["sgst_tax_percentage"]?.toDouble(),
    igstTaxPercentage: json["igst_tax_percentage"],
    itemNameArabic: json["item_name_arabic"],
    itemidx: json["itemidx"],
  );

  Map<String, dynamic> toJson() => {
    "id": id,
    "auto_id": autoId,
    "is_deleted": isDeleted,
    "custom_order": customOrder,
    "alt_txt": altTxt,
    "organization": organization,
    "item_id": itemId,
    "group": group,
    "item_code": itemCode,
    "item_name": itemName,
    "printing_name": printingName,
    "last_item_no": lastItemNo,
    "hsn_code": hsnCode,
    "mrp": mrp,
    "wholesale_price": wholesalePrice,
    "special_price": specialPrice,
    "sale_price": salePrice,
    "locked_price": lockedPrice,
    "purchase_price": purchasePrice,
    "average_purchase_price": averagePurchasePrice,
    "current_stock": currentStock,
    "reorder_level": reorderLevel,
    "remarks": remarks,
    "brand": brand,
    "unit": unit,
    "tax_id": taxId,
    "opening_stock": openingStock,
    "entered_by": enteredBy,
    "entry_date": entryDate.toIso8601String(),
    "subgroup": subgroup,
    "master_item_id": masterItemId,
    "conversion_qty": conversionQty,
    "document_id": documentId,
    "flgdeleted": flgdeleted,
    "opening_stock_purchase_rate": openingStockPurchaseRate,
    "tax_percentage": taxPercentage,
    "basic_rate": basicRate,
    "flg_weighing_scale_item": flgWeighingScaleItem,
    "cost_price": costPrice,
    "kerala_food_cess_percentage": keralaFoodCessPercentage,
    "gst_tax_percentage": gstTaxPercentage,
    "cgst_tax_percentage": cgstTaxPercentage,
    "sgst_tax_percentage": sgstTaxPercentage,
    "igst_tax_percentage": igstTaxPercentage,
    "item_name_arabic": itemNameArabic,
    "itemidx": itemidx,
  };
}
