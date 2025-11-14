import 'package:barcode_widget/barcode_widget.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';

Future<void> printBarcodePdf({
  required String companyName,
  required String productName,
  required String barcode,
  required double? cost,
  required int quantity,
  required double widthMm,
  required double heightMm,
}) async {
  final pdf = pw.Document();
  final pageFormat = PdfPageFormat(
    widthMm * PdfPageFormat.mm,
    heightMm * PdfPageFormat.mm,
    marginAll: 0,
  );

  final bc = Barcode.code128();
  final baseSize = (widthMm < heightMm ? widthMm : heightMm);
  final isSmallFormat = widthMm <= 50 && heightMm <= 30;
  final fontSize = isSmallFormat ? baseSize * 0.20 : baseSize * 0.3;
  final padding = isSmallFormat ? baseSize * 0.11 : baseSize * 0.20;
  final spacing = isSmallFormat ? baseSize * 0.010 : baseSize * 0.02;
  final barcodeHeight = isSmallFormat ? heightMm * 0.30 : heightMm * 0.40;
  for (int i = 0; i < quantity; i++) {
    pdf.addPage(
      pw.Page(
        pageFormat: pageFormat,
        build: (pw.Context context) {
          return pw.Padding(
            padding: pw.EdgeInsets.all(padding),
            child: pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                // pw.Text(
                //   companyName,
                //   maxLines: isSmallFormat ? 1 : 2,
                //   textAlign: pw.TextAlign.start,
                //   style: pw.TextStyle(
                //     fontSize: fontSize,
                //     fontWeight: pw.FontWeight.bold,
                //   ),
                // ),
                pw.Text(
                  productName,
                  maxLines: 1,
                  textAlign: pw.TextAlign.center,
                  style: pw.TextStyle(
                    fontSize: fontSize,
                    fontWeight: pw.FontWeight.normal,
                  ),
                ),
                pw.SizedBox(height: baseSize * 0.01),

                pw.BarcodeWidget(
                  data: barcode,
                  barcode: bc,
                  width: widthMm * 0.85 * PdfPageFormat.mm,
                  height: barcodeHeight * PdfPageFormat.mm,
                  drawText: false,
                ),
                pw.Text(barcode, style: pw.TextStyle(fontSize: fontSize * 0.8)),
                pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.center,
                  children: [
                    pw.SizedBox(height: spacing),
                    pw.Row(
                      mainAxisAlignment: pw.MainAxisAlignment.end,
                      children: [
                        pw.Text(
                          "$cost AED",
                          style: pw.TextStyle(
                            fontSize: baseSize * 0.3,
                            fontWeight: pw.FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  await Printing.layoutPdf(
    onLayout: (PdfPageFormat format) async => pdf.save(),
    format: pageFormat,
  );
}

// Future<void> printBarcodePdfWithPrice({
//   required String productName,
//   required String barcode,
//   required int? cost,
//   required int quantity,
//   required double widthMm,
//   required double heightMm,
// }) async {
//   final pdf = pw.Document();
//   final pageFormat = PdfPageFormat(
//     widthMm * PdfPageFormat.mm,
//     heightMm * PdfPageFormat.mm,
//     marginAll: 0,
//   );

//   final bc = Barcode.code128();
//   final baseSize = (widthMm < heightMm ? widthMm : heightMm);
//   for (int i = 0; i < quantity; i++) {
//     pdf.addPage(
//       pw.Page(
//         pageFormat: pageFormat,
//         build: (pw.Context context) {
//           return pw.Column(
//             mainAxisAlignment: pw.MainAxisAlignment.center,
//             crossAxisAlignment: pw.CrossAxisAlignment.center,
//             children: [
//               pw.Text(
//                 productName,
//                 maxLines: 1,
//                 textAlign: pw.TextAlign.center,
//                 style: pw.TextStyle(
//                   fontSize: baseSize * 0.3,
//                   fontWeight: pw.FontWeight.normal,
//                 ),
//               ),
//               pw.SizedBox(height: baseSize * 0.01),
//               pw.Center(
//                 child: pw.BarcodeWidget(
//                   data: barcode,
//                   barcode: bc,
//                   width: widthMm * 0.85 * PdfPageFormat.mm,
//                   height: heightMm * 0.35 * PdfPageFormat.mm,
//                   drawText: false,
//                 ),
//               ),
//               pw.SizedBox(height: baseSize * 0.01),
//               pw.Text(barcode, style: pw.TextStyle(fontSize: baseSize * 0.3)),
//               pw.Text(
//                 cost.toString(),
//                 style: pw.TextStyle(fontSize: baseSize * 0.3),
//               ),
//             ],
//           );
//         },
//       ),
//     );
//   }

//   await Printing.layoutPdf(
//     onLayout: (PdfPageFormat format) async => pdf.save(),
//     format: pageFormat,
//   );
// }

// Future<void> printBarcodePdfWithCategory({
//   required String productName,
//   required String barcode,
//   required String? category,
//   required int quantity,
//   required double widthMm,
//   required double heightMm,
// }) async {
//   final pdf = pw.Document();
//   final pageFormat = PdfPageFormat(
//     widthMm * PdfPageFormat.mm,
//     heightMm * PdfPageFormat.mm,
//     marginAll: 0,
//   );

//   final bc = Barcode.code128();
//   final baseSize = (widthMm < heightMm ? widthMm : heightMm);
//   for (int i = 0; i < quantity; i++) {
//     pdf.addPage(
//       pw.Page(
//         pageFormat: pageFormat,
//         build: (pw.Context context) {
//           return pw.Column(
//             mainAxisAlignment: pw.MainAxisAlignment.center,
//             crossAxisAlignment: pw.CrossAxisAlignment.center,
//             children: [
//               pw.Center(
//                 child: pw.Text(
//                   productName,
//                   maxLines: 1,
//                   textAlign: pw.TextAlign.center,
//                   style: pw.TextStyle(
//                     fontSize: (baseSize * 0.3),
//                     fontWeight: pw.FontWeight.bold,
//                   ),
//                 ),
//               ),

//               pw.SizedBox(height: baseSize * 0.01),
//               pw.Center(
//                 child: pw.BarcodeWidget(
//                   data: barcode,
//                   barcode: bc,
//                   width: widthMm * 0.9 * PdfPageFormat.mm,
//                   height: heightMm * 0.4 * PdfPageFormat.mm,
//                   drawText: false,
//                 ),
//               ),
//               pw.SizedBox(height: baseSize * 0.01),
//               pw.Center(
//                 child: pw.Text(
//                   barcode,
//                   style: pw.TextStyle(fontSize: baseSize * 0.3),
//                   maxLines: 1,
//                 ),
//               ),

//               pw.Text(
//                 category.toString(),
//                 style: pw.TextStyle(fontSize: baseSize * 0.3),
//                 maxLines: 1,
//               ),
//             ],
//           );
//         },
//       ),
//     );
//   }

//   await Printing.layoutPdf(
//     onLayout: (PdfPageFormat format) async => pdf.save(),
//     format: pageFormat,
//   );
// }
