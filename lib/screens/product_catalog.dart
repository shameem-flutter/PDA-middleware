import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:pda/constants/color_constants.dart';
import 'package:pda/models/count_session.dart';
import 'package:pda/providers/providers.dart';
import 'package:pda/services/authwrapper.dart';
import 'package:pda/screens/countingsession.dart';
import 'package:pda/utilities/gap_func.dart';
import 'package:pda/widgets/textfield.dart';

class ProductCatalogScreen extends ConsumerStatefulWidget {
  const ProductCatalogScreen({super.key});

  @override
  ConsumerState<ProductCatalogScreen> createState() =>
      _ProductCatalogScreenState();
}

class _ProductCatalogScreenState extends ConsumerState<ProductCatalogScreen> {
  final TextEditingController _searchController = TextEditingController();

  final ScrollController _scrollController = ScrollController();
  final FocusNode _searchFocusNode = FocusNode();

  @override
  void initState() {
    super.initState();
    _searchController.text = ref.read(searchQueryProvider);
    _searchController.addListener(() {
      ref.read(searchQueryProvider.notifier).state = _searchController.text;
    });
  }

  @override
  void dispose() {
    _scrollController.dispose();
    _searchFocusNode.dispose();
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final productsAsync = ref.watch(productsNotifierProvider);
    final displayedProducts = ref.watch(filteredProductsProvider);
    final sessionsAsync = ref.watch(sessionsNotifierProvider);
    return Scaffold(
      appBar: AppBar(
        backgroundColor: primaryColor,
        title: Text(
          "Product Catalog",
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: onSecondaryColor,
          ),
        ),
        centerTitle: true,
        automaticallyImplyLeading: false,
        actions: [
          IconButton(
            onPressed: () {
              showDialog(
                context: context,
                builder: (dialogContext) => AlertDialog(
                  title: Text("Log-Out?"),
                  content: Text("Are you sure?"),
                  actions: [
                    TextButton(
                      onPressed: () => Navigator.of(dialogContext).pop(),
                      child: Text("Cancel"),
                    ),
                    TextButton(
                      onPressed: () async {
                        Navigator.of(dialogContext).pop();
                        showDialog(
                          context: context,
                          barrierDismissible: false,
                          builder: (context) => Center(
                            child: CircularProgressIndicator(
                              color: primaryColor,
                            ),
                          ),
                        );
                        await ref.read(authNotifierProvider.notifier).logout();

                        if (context.mounted) {
                          Navigator.of(context).pop();
                          Navigator.pushAndRemoveUntil(
                            context,
                            MaterialPageRoute(
                              builder: (context) =>
                                  AuthWrapper(showLogOutSnackBar: true),
                            ),
                            (route) => false,
                          );
                        }
                      },
                      child: const Text("Log-Out"),
                    ),
                  ],
                ),
              );
            },
            icon: Icon(Icons.logout, color: surfaceColor),
          ),
        ],
      ),
      body: LayoutBuilder(
        builder: (context, constraints) {
          return Column(
            children: [
              Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 5,
                ),
                child: SearchField(
                  controller: _searchController,
                  focusNode: _searchFocusNode,
                  hintText: "Search products",
                  padding: EdgeInsets.symmetric(horizontal: 10),
                  onChanged: (value) {
                    ref.read(searchQueryProvider.notifier).state = value;
                  },
                ),
              ),

              Expanded(
                child: productsAsync.when(
                  loading: () => Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        CircularProgressIndicator(color: primaryColor),
                        vertGap(16),
                        Text("Syncing all products, please wait"),
                      ],
                    ),
                  ),
                  error: (error, stackTrace) =>
                      Center(child: Text("Error: $error")),
                  data: (_) => sessionsAsync.when(
                    loading: () => Center(
                      child: CircularProgressIndicator(color: primaryColor),
                    ),
                    error: (error, stackTrace) =>
                        Center(child: Text("Error: $error")),
                    data: (sessions) => displayedProducts.isEmpty
                        ? const Center(child: Text("No products found"))
                        : RefreshIndicator(
                            onRefresh: () async {
                              final messenger = ScaffoldMessenger.of(context);
                              try {
                                await ref
                                    .read(productsNotifierProvider.notifier)
                                    .syncProducts();
                                if (mounted) {
                                  messenger.showSnackBar(
                                    SnackBar(
                                      content: Text("Syncing-Completed"),
                                      duration: Duration(seconds: 1),
                                      backgroundColor: successColor,
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(12),
                                      ),
                                      behavior: SnackBarBehavior.floating,
                                    ),
                                  );
                                }
                              } catch (e) {
                                if (mounted) {
                                  messenger.showSnackBar(
                                    SnackBar(
                                      content: Text("failed to sync-data!!!"),
                                      duration: Duration(seconds: 2),
                                      backgroundColor: errorColor,
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(12),
                                      ),
                                      behavior: SnackBarBehavior.floating,
                                    ),
                                  );
                                }
                              }
                            },

                            child: ListView.separated(
                              separatorBuilder: (_, _) => vertGap(5),
                              controller: _scrollController,
                              itemCount: displayedProducts.length,
                              itemBuilder: (context, index) {
                                final product = displayedProducts[index];
                                final existingSession = sessions.firstWhere(
                                  (session) => session.productId == product.id,
                                  orElse: () => CountingSession(
                                    productId: product.id!,
                                    countedQuantity: 0,
                                    erpQuantity: product.erpQuantity,
                                    productName: product.name,
                                  ),
                                );
                                final hasSession =
                                    existingSession.countedQuantity > 0;

                                return InkWell(
                                  onTap: () async {
                                    _searchFocusNode.unfocus();
                                    final dbHelper = ref.read(dbProvider);
                                    final navigator = Navigator.of(context);
                                    await dbHelper.insertOrUpdateProduct(
                                      product,
                                    );

                                    if (mounted) return;
                                    await navigator.push<bool>(
                                      MaterialPageRoute(
                                        builder: (_) => CountingSessionScreen(
                                          product: product,
                                          initialCounted:
                                              existingSession.countedQuantity,
                                        ),
                                      ),
                                    );
                                  },
                                  child: Padding(
                                    padding: const EdgeInsets.symmetric(
                                      vertical: 5,
                                    ),
                                    child: ListTile(
                                      leading: Icon(Icons.image, size: 70),
                                      trailing: Column(
                                        mainAxisAlignment:
                                            MainAxisAlignment.spaceEvenly,
                                        children: [
                                          Text("${product.erpQuantity}"),
                                          const Text("in stock"),
                                          if (hasSession)
                                            Text(
                                              "Counted: ${existingSession.countedQuantity}",
                                              style: TextStyle(
                                                color: successColor,
                                              ),
                                            ),
                                        ],
                                      ),
                                      title: Text(
                                        product.name,
                                        style: TextStyle(
                                          fontWeight: FontWeight.bold,
                                          color: hasSession
                                              ? successColor
                                              : null,
                                        ),
                                      ),
                                      subtitle: Text(
                                        product.barcode.toString(),
                                      ),
                                    ),
                                  ),
                                );
                              },
                            ),
                          ),
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}
