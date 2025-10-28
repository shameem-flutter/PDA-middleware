import 'package:flutter/material.dart';
import 'package:pda/constants/color_constants.dart';
import 'package:pda/models/products.dart';
import 'package:pda/utilities/gap_func.dart';
import 'package:pda/utilities/printhelper.dart';
import 'package:pda/widgets/customappbartitle.dart';

class PrintingScreen extends StatefulWidget {
  final Product product;
  const PrintingScreen({super.key, required this.product});

  @override
  State<PrintingScreen> createState() => _PrintingScreenState();
}

class _PrintingScreenState extends State<PrintingScreen>
    with SingleTickerProviderStateMixin {
  final TextEditingController _qtyController = TextEditingController(text: "1");
  final TextEditingController _widthController = TextEditingController();
  final TextEditingController _heightController = TextEditingController();
  String _selectedFormat = "38x25 mm";
  String selectedTemplate = "default";

  final List<String> _templates = [
    "default",
    //  "with price",
    //  "category name"
  ];
  List<String> labelFormats = [
    "38x25 mm",
    "51x178 mm",
    "102x178 mm",
    "102x305 mm",
    "Custom",
  ];
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const CustomAppBarTitle(title: "Print Barcode"),
        iconTheme: IconThemeData(color: onSecondaryColor),
        centerTitle: true,
        elevation: 0,
        backgroundColor: primaryColor,
      ),
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [onSecondaryColor, const Color(0xFFF1F5F9)],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
        ),
        child: LayoutBuilder(
          builder: (context, constraints) {
            return SingleChildScrollView(
              child: ConstrainedBox(
                constraints: BoxConstraints(minHeight: constraints.maxHeight),
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 20,
                    vertical: 30,
                  ),
                  child: Column(
                    children: [
                      Card(
                        color: onSecondaryColor,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(15),
                          side: BorderSide(color: primaryColor, width: 1),
                        ),
                        elevation: 8,
                        child: Padding(
                          padding: const EdgeInsets.all(16),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Icon(
                                    Icons.label,
                                    color: primaryColor,
                                    size: 28,
                                  ),
                                  horiGap(16),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          widget.product.name,
                                          maxLines: 2,
                                          style: const TextStyle(
                                            fontSize: 16,
                                            fontWeight: FontWeight.w700,
                                            color: Colors.black87,
                                          ),
                                        ),
                                        Text(
                                          "Barcode: ${widget.product.barcode ?? "-"}",
                                          style: TextStyle(
                                            fontSize: 14,
                                            color: Colors.grey[600],
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                              // const SizedBox(height: 20),
                              // TextField(
                              //   controller: _qtyController,
                              //   decoration: InputDecoration(
                              //     labelText: "No.of Labels",
                              //     labelStyle: TextStyle(
                              //       color: Colors.grey[700],
                              //       fontSize: 16,
                              //     ),
                              //     border: OutlineInputBorder(
                              //       borderRadius: BorderRadius.circular(12),
                              //     ),
                              //   ),
                              //   keyboardType: TextInputType.number,
                              //   style: const TextStyle(
                              //     fontSize: 14,
                              //     color: Colors.black87,
                              //   ),
                              // ),
                              vertGap(10),
                              Text(
                                "Template:",
                                style: const TextStyle(
                                  fontSize: 20,
                                  fontWeight: FontWeight.w600,
                                  color: Colors.black87,
                                ),
                              ),
                              vertGap(8),
                              DropdownButtonFormField<String>(
                                borderRadius: BorderRadius.circular(12),
                                dropdownColor: onSecondaryColor,
                                initialValue: selectedTemplate,
                                items: _templates
                                    .map(
                                      (template) => DropdownMenuItem<String>(
                                        value: template,
                                        child: Text(
                                          template
                                              .replaceAll("_", " ")
                                              .toUpperCase(),
                                          style: TextStyle(
                                            color: primaryColor,
                                            fontWeight: FontWeight.w700,
                                          ),
                                        ),
                                      ),
                                    )
                                    .toList(),
                                onChanged: (value) {
                                  if (value != null) {
                                    setState(() {
                                      selectedTemplate = value;
                                    });
                                  }
                                },
                                selectedItemBuilder: (context) {
                                  return _templates.map((e) {
                                    return Text(
                                      e.replaceAll("_", " ").toUpperCase(),
                                      style: TextStyle(
                                        color: onSurfaceColor,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    );
                                  }).toList();
                                },

                                decoration: InputDecoration(
                                  contentPadding: const EdgeInsets.symmetric(
                                    horizontal: 12,
                                    vertical: 14,
                                  ),

                                  border: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                ),
                                style: TextStyle(color: onSurfaceColor),
                              ),

                              vertGap(14),
                              Text(
                                "Label Format",
                                style: const TextStyle(
                                  fontSize: 20,
                                  fontWeight: FontWeight.w600,
                                  color: Colors.black87,
                                ),
                              ),
                              Column(
                                children: List.generate(
                                  labelFormats.length,
                                  (index) => RadioMenuButton<String>(
                                    value: labelFormats[index],
                                    style: ButtonStyle(
                                      shape: WidgetStateProperty.all(
                                        RoundedRectangleBorder(
                                          borderRadius: BorderRadius.circular(
                                            12,
                                          ),
                                        ),
                                      ),
                                    ),
                                    groupValue: _selectedFormat,
                                    onChanged: (value) => setState(() {
                                      _selectedFormat = value!;
                                    }),

                                    child: Text(labelFormats[index]),
                                  ),
                                ),
                              ),

                              if (_selectedFormat.toLowerCase() ==
                                  "custom") ...[
                                vertGap(15),
                                Row(
                                  children: [
                                    Expanded(
                                      child: TextField(
                                        controller: _widthController,
                                        decoration: InputDecoration(
                                          labelText: "Width",
                                          labelStyle: TextStyle(
                                            color: Colors.grey[700],
                                            fontSize: 16,
                                          ),
                                          border: OutlineInputBorder(
                                            borderRadius: BorderRadius.circular(
                                              12,
                                            ),
                                          ),
                                        ),
                                        keyboardType: TextInputType.number,
                                        style: const TextStyle(
                                          fontSize: 18,
                                          color: Colors.black87,
                                        ),
                                      ),
                                    ),
                                    horiGap(15),
                                    Expanded(
                                      child: TextField(
                                        controller: _heightController,
                                        decoration: InputDecoration(
                                          labelText: "Height",
                                          labelStyle: TextStyle(
                                            color: Colors.grey[700],
                                            fontSize: 16,
                                          ),
                                          border: OutlineInputBorder(
                                            borderRadius: BorderRadius.circular(
                                              12,
                                            ),
                                          ),
                                        ),
                                        keyboardType: TextInputType.number,
                                        style: const TextStyle(
                                          fontSize: 18,
                                          color: Colors.black87,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ],
                          ),
                        ),
                      ),
                      vertGap(30),
                      Center(
                        child: ElevatedButton.icon(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: primaryColor,
                            foregroundColor: onSecondaryColor,
                            padding: const EdgeInsets.symmetric(
                              horizontal: 24,
                              vertical: 14,
                            ),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(25),
                            ),
                            elevation: 10,
                            shadowColor: primaryColor.withValues(alpha: 0.5),
                          ),
                          icon: const Icon(Icons.print, size: 22),
                          label: const Text(
                            "Generate & Print",
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          onPressed: () async {
                            final qty = int.tryParse(_qtyController.text) ?? 1;
                            double widthMm = 38, heightMm = 25;
                            if (_selectedFormat == "custom") {
                              widthMm =
                                  double.tryParse(_widthController.text) ?? 50;
                              heightMm =
                                  double.tryParse(_heightController.text) ?? 30;
                            }
                            if (_selectedFormat == "51x178 mm") {
                              widthMm = 51;
                              heightMm = 178;
                            }
                            if (_selectedFormat == "102x178 mm") {
                              widthMm = 102;
                              heightMm = 178;
                            }
                            if (_selectedFormat == "102x305 mm") {
                              widthMm = 102;
                              heightMm = 305;
                            }
                            if (selectedTemplate == "default") {
                              await printBarcodePdf(
                                companyName: widget.product.companyName
                                    .toString(),
                                cost: widget.product.cost,
                                productName: widget.product.name,
                                barcode: widget.product.barcode ?? "",
                                quantity: qty,
                                widthMm: widthMm,
                                heightMm: heightMm,
                              );
                            }

                            // if (selectedTemplate == "with price") {
                            //   await printBarcodePdfWithPrice(
                            //     productName: widget.product.name,
                            //     barcode: widget.product.barcode!,
                            //     cost: widget.product.cost,
                            //     quantity: qty,
                            //     widthMm: widthMm,
                            //     heightMm: heightMm,
                            //   );
                            // }

                            // if (selectedTemplate == "category name") {
                            //   await printBarcodePdfWithCategory(
                            //     productName: widget.product.name,
                            //     barcode: widget.product.barcode!,
                            //     category: widget.product.categoryName,
                            //     quantity: qty,
                            //     widthMm: widthMm,
                            //     heightMm: heightMm,
                            //   );
                            // }
                          },
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}
