import 'package:barcode_widget/barcode_widget.dart';
import 'package:pdf/widgets.dart' as pw;

class BarcodeHelper {
  static BarcodeWidget buildUiBarcode(
    String value, {
    double width = 200,
    double height = 80,
  }) {
    return BarcodeWidget(
      barcode: Barcode.code128(),
      data: value,
      width: width,
      height: height,
      drawText: true,
    );
  }

  static pw.Widget buildPdfBarcode(
    String value, {
    double width = 200,
    double height = 80,
  }) {
    return pw.BarcodeWidget(
      barcode: pw.Barcode.code128(),
      data: value,
      width: width,
      height: height,
      drawText: true,
    );
  }
}
