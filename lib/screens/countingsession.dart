import 'package:barcode_widget/barcode_widget.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:pda/constants/color_constants.dart';
import 'package:pda/models/products.dart';
import 'package:pda/providers/navigation_provider.dart';
import 'package:pda/providers/providers.dart';
import 'package:pda/screens/printingscreen.dart';
import 'package:pda/utilities/gap_func.dart';
import 'package:pda/widgets/custombutton.dart';
import 'package:pda/widgets/custombutton2.dart';

class CountingSessionScreen extends ConsumerStatefulWidget {
  final Product product;
  final int? initialCounted;
  const CountingSessionScreen({
    super.key,
    required this.product,
    this.initialCounted = 0,
  });

  @override
  ConsumerState<CountingSessionScreen> createState() =>
      _CountingSessionScreenState();
}

class _CountingSessionScreenState extends ConsumerState<CountingSessionScreen> {
  late int _counted;

  @override
  void initState() {
    super.initState();
    _counted = widget.initialCounted ?? 0;
  }

  void _increment() => setState(() => _counted++);

  void _decrease() {
    if (_counted > 0) setState(() => _counted--);
  }

  @override
  Widget build(BuildContext context) {
    final counted = _counted;
    final erpQuantity = widget.product.erpQuantity;
    final difference = erpQuantity - counted;

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        iconTheme: IconThemeData(color: surfaceColor),
        toolbarHeight: 70,
        backgroundColor: primaryColor,
        title: Text(
          "Counting Session",
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: onSecondaryColor,
          ),
        ),
        centerTitle: true,
        actions: [
          IconButton(
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => PrintingScreen(product: widget.product),
                ),
              );
            },
            icon: const Icon(Icons.print, color: Colors.white),
          ),
        ],
      ),
      body: Material(
        color: Colors.white,
        child: LayoutBuilder(
          builder: (context, constraints) {
            return SingleChildScrollView(
              child: ConstrainedBox(
                constraints: BoxConstraints(minHeight: constraints.maxHeight),
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 20,
                    vertical: 20,
                  ),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      Text(
                        widget.product.name,
                        style: const TextStyle(
                          fontWeight: FontWeight.w700,
                          fontSize: 20,
                        ),
                      ),
                      Container(
                        decoration: BoxDecoration(
                          color: fadeColor,
                          borderRadius: BorderRadius.circular(5),
                        ),
                        child: Text("Product-Id:${widget.product.productId}"),
                      ),
                      vertGap(10),

                      if (widget.product.barcode != null &&
                          widget.product.barcode!.isNotEmpty)
                        Center(
                          child: SizedBox(
                            width: 250,
                            height: 110,
                            child: BarcodeWidget(
                              data: widget.product.barcode!,
                              barcode: Barcode.code128(),
                              width: 250,
                              height: 110,
                              drawText: true,
                            ),
                          ),
                        )
                      else
                        const Text("No barcode available"),
                    vertGap(20),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        _circleButton(Icons.remove, _decrease),
                        horiGap(15),
                        Text(
                          counted.toString(),
                          style: TextStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        horiGap(15),
                        _circleButton(Icons.add, _increment),
                      ],
                    ),
                    vertGap(30),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      mainAxisSize: MainAxisSize.max,
                      children: [
                        _columnRow(
                          "ERP Quantity",
                          erpQuantity.toString(),
                          onBackgroundColor,
                        ),
                        _columnRow(
                          "Counted",
                          counted.toString(),
                          secondaryColor,
                        ),
                        _columnRow(
                          "Difference",
                          difference.toString(),
                          difference < erpQuantity ? errorColor : successColor,
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    ),
      bottomNavigationBar: Container(
        height: 80,
        decoration: BoxDecoration(color: onPrimaryColor),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: [
            CustomButton(
              text: "Cancel",
              onPressed: () {
                Navigator.pop(context, false);
              },
              padding: EdgeInsets.symmetric(horizontal: 25, vertical: 12),
            ),
            CustomButton2(
              text: "Save & Continue",
              onPressed: () async {
                final messenger = ScaffoldMessenger.of(context);
                final dbHelper = ref.read(dbProvider);

                if (counted > 0) {
                  // Ensure product is inserted/updated in SQLite database
                  await dbHelper.insertOrUpdateProduct(widget.product);

                  // Resolve non-null primary key integer ID
                  int? effectiveId = widget.product.id;
                  if (effectiveId == null &&
                      widget.product.barcode != null &&
                      widget.product.barcode!.isNotEmpty) {
                    final savedProduct = await dbHelper
                        .getProductByBarcode(widget.product.barcode!);
                    effectiveId = savedProduct?.id;
                  }

                  if (effectiveId == null) {
                    messenger.showSnackBar(
                      const SnackBar(
                        content: Text(
                          "Product ID missing. Please reload catalog.",
                        ),
                      ),
                    );
                    return;
                  }

                  final productInDb =
                      await dbHelper.getProductById(effectiveId);
                  if (productInDb == null) {
                    messenger.showSnackBar(
                      const SnackBar(
                        content: Text(
                          "Product not synced. Please refresh catalog.",
                        ),
                        duration: Duration(milliseconds: 600),
                      ),
                    );
                    return;
                  }

                  // Update if session already exists, otherwise create
                  final hasExistingSession = (widget.initialCounted ?? 0) > 0;
                  if (hasExistingSession) {
                    await ref
                        .read(sessionsNotifierProvider.notifier)
                        .updateSession(effectiveId, counted);
                  } else {
                    await ref
                        .read(sessionsNotifierProvider.notifier)
                        .createSession(effectiveId, counted);
                  }
                  WidgetsBinding.instance.addPostFrameCallback((_) {
                    if (context.mounted) {
                      Navigator.pop(context, true);
                      ref.read(tabNavigationProvider).switchToReview();
                    }
                  });
                  // if (!mounted) return;
                  // EventBus().notifyProductUpdated(widget.product.id!, counted);
                  // EventBus().notifySessionChanged();
                  // // EventBus().switchToTab(2);
                  // Navigator.pop(context, true);
                } else {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text("Set a Count"),
                      duration: Duration(milliseconds: 400),
                    ),
                  );
                }
              },
              padding: EdgeInsets.symmetric(horizontal: 15, vertical: 12),
            ),
          ],
        ),
      ),
    );
  }

  Widget _circleButton(IconData icon, VoidCallback onPressed) {
    return InkWell(
      onTap: onPressed,
      child: CircleAvatar(
        radius: 26,
        backgroundColor: primaryColor,
        child: Icon(icon, color: onPrimaryColor),
      ),
    );
  }

  Widget _columnRow(String title, String value, Color color) {
    return Column(
      children: [
        Text(
          title,
          style: TextStyle(
            fontSize: 17,
            fontWeight: FontWeight.w500,
            color: formfieldColor,
          ),
        ),
        Text(
          value,
          style: TextStyle(
            color: color,
            fontSize: 16,
            fontWeight: FontWeight.w700,
          ),
        ),
      ],
    );
  }
}
