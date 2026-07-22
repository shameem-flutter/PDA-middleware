import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:pda/constants/color_constants.dart';
import 'package:pda/models/count_session.dart';
import 'package:pda/providers/navigation_provider.dart';
import 'package:pda/providers/providers.dart';
import 'package:pda/screens/details_screen.dart';
import 'package:pda/utilities/gap_func.dart';
import 'package:pda/widgets/card.dart';

class ReviewCount extends ConsumerStatefulWidget {
  const ReviewCount({super.key});

  @override
  ConsumerState<ReviewCount> createState() => _ReviewCountState();
}

class _ReviewCountState extends ConsumerState<ReviewCount> {
  final Map<int, TextEditingController> _controllers = {};

  @override
  void dispose() {
    for (final c in _controllers.values) {
      c.dispose();
    }
    super.dispose();
  }

  TextEditingController _getController(CountingSession session) {
    final existing = _controllers[session.productId];
    if (existing == null) {
      final c = TextEditingController(text: session.countedQuantity.toString());
      _controllers[session.productId] = c;
      return c;
    }

    if (existing.text != session.countedQuantity.toString()) {
      existing.text = session.countedQuantity.toString();
    }

    return existing;
  }

  @override
  Widget build(BuildContext context) {
    final sessionsAsync = ref.watch(sessionsNotifierProvider);
    final scaffoldMessenger = ScaffoldMessenger.of(context);

    // ✅ REMOVED WillPopScope - let parent Home widget handle back button
    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          onPressed: () => ref.read(tabNavigationProvider).switchToCatalog(),
          icon: const Icon(Icons.arrow_back, color: surfaceColor),
        ),
        title: const Text(
          "Review Count",
          style: TextStyle(
            color: onSecondaryColor,
            fontSize: 16,
            fontWeight: FontWeight.bold,
          ),
        ),
        backgroundColor: primaryColor,
        centerTitle: true,
      ),
      body: sessionsAsync.when(
        loading: () => const Center(
          child: CircularProgressIndicator(color: primaryColor),
        ),
        error: (err, stack) => Center(
          child: Text("Error loading sessions: $err"),
        ),
        data: (sessions) {
          if (sessions.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.fact_check_outlined, size: 64, color: Colors.grey.shade400),
                  vertGap(12),
                  Text(
                    "No Counted Sessions Yet",
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: Colors.grey.shade700,
                    ),
                  ),
                  vertGap(6),
                  Text(
                    "Scan or select products to begin counting",
                    style: TextStyle(
                      fontSize: 13,
                      color: Colors.grey.shade500,
                    ),
                  ),
                ],
              ),
            );
          }

          return ListView.separated(
            padding: const EdgeInsets.only(bottom: 80),
            separatorBuilder: (_, _) => vertGap(0),
            itemCount: sessions.length,
            itemBuilder: (context, index) {
              final session = sessions[index];
              final controller = _getController(session);
              final navigator = Navigator.of(context);
              return InkWell(
                onTap: () async {
                  final dbHelper = ref.read(dbProvider);
                  final product = await dbHelper.getProductById(
                    session.productId,
                  );

                  if (mounted && product != null) {
                    navigator.push(
                      MaterialPageRoute(
                        builder: (_) => DetailsScreen(
                          product: product,
                          countingSession: session,
                        ),
                      ),
                    );
                  }
                },
                child: CustomCard(
                  title: session.productName ?? "",
                  subtitle: 'Product-Id: ${session.productId}',
                  info1: "Counted: ${session.countedQuantity}",
                  info2: "ERP: ${session.erpQuantity}",
                  customWidget: _quantityBuilder(session, controller),
                  iconButton2: IconButton(
                    icon: const Icon(Icons.delete, color: errorColor),
                    onPressed: () async {
                      final confirm = await showDialog<bool>(
                        context: context,
                        builder: (ctx) => AlertDialog(
                          title: const Text("Delete"),
                          content: Text(
                            "Delete ${session.productName ?? 'this product'}?",
                          ),
                          actions: [
                            TextButton(
                              onPressed: () => Navigator.pop(ctx, false),
                              child: const Text("Cancel"),
                            ),
                            TextButton(
                              onPressed: () => Navigator.pop(ctx, true),
                              child: const Text("Delete"),
                            ),
                          ],
                        ),
                      );

                      if (confirm != true) return;

                      await ref
                          .read(sessionsNotifierProvider.notifier)
                          .deleteSession(session.id!);

                      if (!mounted) return;

                      WidgetsBinding.instance.addPostFrameCallback((_) {
                        scaffoldMessenger.showSnackBar(
                          SnackBar(
                            content: Text(
                              "${session.productName ?? 'Item'} deleted❗",
                            ),
                            duration: const Duration(milliseconds: 800),
                          ),
                        );
                      });
                    },
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }

  Widget _quantityBuilder(
    CountingSession session,
    TextEditingController controller,
  ) {
    return Builder(
      builder: (context) {
        return OutlinedButton(
          onPressed: () async {
            final RenderBox button = context.findRenderObject() as RenderBox;
            final overlay =
                Overlay.of(context).context.findRenderObject() as RenderBox;
            final position = RelativeRect.fromRect(
              Rect.fromPoints(
                button.localToGlobal(Offset.zero, ancestor: overlay),
                button.localToGlobal(
                  button.size.bottomRight(Offset.zero),
                  ancestor: overlay,
                ),
              ),
              Offset.zero & overlay.size,
            );

            final selected = await showMenu<String>(
              context: context,
              position: position,
              items: const [
                PopupMenuItem(value: "1", child: Text("1")),
                PopupMenuItem(value: "2", child: Text("2")),
                PopupMenuItem(value: "3", child: Text("3")),
                PopupMenuItem(value: "More", child: Text("More")),
              ],
            );

            if (!mounted || selected == null) return;

            if (selected == "More") {
              if (!context.mounted) return;
              await showDialog(
                context: context,
                builder: (ctx) => AlertDialog(
                  title: const Text("Enter Quantity"),
                  content: TextField(
                    controller: controller,
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(
                      labelText: "New Quantity",
                    ),
                  ),
                  actions: [
                    TextButton(
                      onPressed: () => Navigator.pop(ctx),
                      child: const Text("Cancel"),
                    ),
                    TextButton(
                      onPressed: () {
                        final newQty = int.tryParse(controller.text) ?? 0;
                        if (newQty > 0) {
                          ref
                              .read(sessionsNotifierProvider.notifier)
                              .updateSession(session.productId, newQty)
                              .then((_) {
                                controller.text = newQty.toString();
                                ref
                                    .read(sessionsNotifierProvider.notifier)
                                    .loadSessions();
                              });
                        }

                        Navigator.pop(ctx);
                      },
                      child: const Text("Apply"),
                    ),
                  ],
                ),
              );
            } else {
              final newQty = int.parse(selected);
              ref
                  .read(sessionsNotifierProvider.notifier)
                  .updateSession(session.productId, newQty);
            }
          },
          style: OutlinedButton.styleFrom(
            foregroundColor: Colors.black,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8),
              side: BorderSide(color: Colors.grey.withValues(alpha: 0.2)),
            ),
            padding: const EdgeInsets.symmetric(horizontal: 8),
          ),
          child: Row(
            children: [
              horiGap(6),
              Text("QTY: ${session.countedQuantity}"),
              const Icon(Icons.arrow_drop_down_outlined),
            ],
          ),
        );
      },
    );
  }
}
