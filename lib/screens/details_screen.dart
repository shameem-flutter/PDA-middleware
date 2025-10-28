import 'package:flutter/material.dart';
import 'package:pda/constants/color_constants.dart';
import 'package:pda/models/count_session.dart';
import 'package:pda/models/products.dart';
import 'package:pda/utilities/gap_func.dart';

class DetailsScreen extends StatefulWidget {
  final Product product;
  final CountingSession countingSession;

  const DetailsScreen({
    super.key,
    required this.product,
    required this.countingSession,
  });

  @override
  State<DetailsScreen> createState() => _DetailsScreenState();
}

class _DetailsScreenState extends State<DetailsScreen> {
  late final Product product;
  late final CountingSession countingSession;

  @override
  void initState() {
    super.initState();
    product = widget.product;
    countingSession = widget.countingSession;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: surfaceColor,
      appBar: AppBar(
        iconTheme: IconThemeData(color: surfaceColor),
        backgroundColor: primaryColor,
        title: const Text(
          "Product Details",
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: onSecondaryColor,
          ),
        ),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Card(
          color: Colors.white,
          elevation: 4,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Container(
                  height: 120,
                  width: 120,
                  decoration: BoxDecoration(
                    color: primaryColor.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: const Icon(Icons.image, size: 60, color: Colors.grey),
                ),
                vertGap(16),
                Text(
                  product.name,
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                  textAlign: TextAlign.center,
                ),
                vertGap(20),

                _buildDetailTile("Barcode", product.barcode),
                _buildDetailTile(
                  "Counted Quantity",
                  countingSession.countedQuantity.toString(),
                ),
                _buildDetailTile(
                  "ERP Quantity",
                  countingSession.erpQuantity.toString(),
                ),
                _buildDetailTile("Company Name", product.companyName),
                _buildDetailTile("Category Name", product.categoryName),
                _buildDetailTile("Category ID", product.categoryId?.toString()),
                _buildDetailTile("Sale Price", product.salePrice?.toString()),
                _buildDetailTile("Cost", product.cost?.toString()),
                _buildDetailTile("UOM Name", product.uomName),
                _buildDetailTile("References", product.reference),
                _buildDetailTile("Product ID", product.productId?.toString()),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildDetailTile(String label, String? value) {
    return Column(
      children: [
        ListTile(
          dense: true,
          contentPadding: EdgeInsets.zero,
          title: Text(
            "$label:",
            style: const TextStyle(fontWeight: FontWeight.bold),
          ),
          trailing: Text(
            "$value",
            style: TextStyle(color: primaryColor),
            textAlign: TextAlign.end,
            overflow: TextOverflow.ellipsis,
          ),
        ),
        const Divider(height: 1),
      ],
    );
  }
}
