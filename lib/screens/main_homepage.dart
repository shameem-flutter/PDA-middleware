import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:pda/constants/color_constants.dart';
import 'package:pda/home.dart';
import 'package:pda/providers/navigation_provider.dart';
import 'package:pda/providers/providers.dart';
import 'package:pda/screens/settings_screen.dart';
import 'package:pda/services/authwrapper.dart';
import 'package:pda/utilities/gap_func.dart';

class MyHomePage extends ConsumerStatefulWidget {
  // final VoidCallback? onLogOut;
  final bool usePushNavigation;
  const MyHomePage({super.key, this.usePushNavigation = true});

  @override
  ConsumerState<MyHomePage> createState() => _MyHomePageState();
}

class _MyHomePageState extends ConsumerState<MyHomePage> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(),
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) {
            final screenWidth = constraints.maxWidth;
            final crossAxisCount = screenWidth > 600 ? 3 : 2;
            final horizontalPadding = screenWidth > 600 ? 40.0 : 15.0;

            return SingleChildScrollView(
              child: Padding(
                padding: EdgeInsets.symmetric(
                  horizontal: horizontalPadding,
                  vertical: 20,
                ),
                child: Column(
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          "PDA Inventory Manager",
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            color: primaryColor,
                            fontSize: screenWidth > 600 ? 28 : 24,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                      ],
                    ),
                    vertGap(25),
                    GridView.count(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      crossAxisCount: crossAxisCount,
                      crossAxisSpacing: 0,
                      mainAxisSpacing: 0,
                      childAspectRatio: 0.90,
                      children: [
                        _buildGridItem(
                          context,
                          imagePath: 'assets/images/manageinventory.png',
                          label: 'Manage Inventory',
                          onPressed: () => _navigateToScreen(1),
                        ),
                        _buildGridItem(
                          context,
                          imagePath: 'assets/images/print_barcode.png',
                          label: 'Print Barcode',
                          // TODO: navigate to dedicated print screen
                          onPressed: () => _navigateToScreen(1),
                        ),
                        _buildGridItem(
                          context,
                          imagePath: 'assets/images/product_search2.png',
                          label: 'Product Search',
                          // TODO: navigate to dedicated search screen
                          onPressed: () => _navigateToScreen(1),
                        ),
                        _buildGridItem(
                          context,
                          icon: Icons.sync,
                          label: 'Sync Data',
                          onPressed: () => _syncData(),
                        ),
                      ],
                    ),
                    SizedBox(height: constraints.maxHeight * 0.05),
                  ],
                ),
              ),
            );
          },
        ),
      ),
      bottomNavigationBar: SafeArea(
        child: BottomNavigationBar(
          elevation: 0,
          items: const [
            BottomNavigationBarItem(
              icon: Icon(Icons.settings, color: primaryColor),
              label: 'Settings',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.logout, color: primaryColor),
              label: 'Logout',
            ),
          ],
          onTap: (index) async {
            final navigator = Navigator.of(context);
            if (index == 1) {
              final confirmed = await showDialog<bool>(
                context: context,
                builder: (dialogContext) => AlertDialog(
                  title: const Text("Log-Out?"),
                  content: const Text("Are you sure?"),
                  actions: [
                    TextButton(
                      onPressed: () => Navigator.of(dialogContext).pop(false),
                      child: const Text("Cancel"),
                    ),
                    TextButton(
                      onPressed: () => Navigator.of(dialogContext).pop(true),
                      child: const Text("Log-Out"),
                    ),
                  ],
                ),
              );

              if (confirmed == true) {
                if (!context.mounted) return;
                showDialog(
                  context: context,
                  barrierDismissible: false,
                  builder: (_) => Center(
                    child: CircularProgressIndicator(color: primaryColor),
                  ),
                );

                await ref.read(authNotifierProvider.notifier).logout();

                if (context.mounted) {
                  navigator.pop();
                  navigator.pushAndRemoveUntil(
                    MaterialPageRoute(
                      builder: (_) =>
                          const AuthWrapper(showLogOutSnackBar: true),
                    ),
                    (route) => false,
                  );
                }
              }
            }
            if (index == 0) {
              navigator.push(
                MaterialPageRoute(builder: (context) => const SettingsScreen()),
              );
            }
          },
          selectedItemColor: primaryColor,
          unselectedItemColor: primaryColor,
        ),
      ),
    );
  }

  void _navigateToScreen(int index) {
    if (widget.usePushNavigation) {
      Navigator.push(
        context,
        MaterialPageRoute(builder: (context) => Home(initialIndex: index)),
      );
    } else {
      if (index == 3) {
        ref.read(tabNavigationProvider).switchToReview();
      } else {
        ref.read(tabNavigationProvider).switchToCatalog();
      }
    }
  }

  Future<void> _syncData() async {
    final messenger = ScaffoldMessenger.of(context);
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => Center(
        child: Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              CircularProgressIndicator(color: primaryColor),
              vertGap(16),
              const Text(
                "Syncing catalog data...",
                style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
              ),
            ],
          ),
        ),
      ),
    );

    try {
      await ref.read(productsNotifierProvider.notifier).syncProducts();
      if (mounted) {
        Navigator.of(context, rootNavigator: true).pop();
        messenger.showSnackBar(
          SnackBar(
            content: const Text("Sync completed successfully"),
            duration: const Duration(seconds: 2),
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
        Navigator.of(context, rootNavigator: true).pop();
        messenger.showSnackBar(
          SnackBar(
            content: Text("Sync failed: $e"),
            duration: const Duration(seconds: 2),
            backgroundColor: errorColor,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    }
  }

  Widget _buildGridItem(
    BuildContext context, {
    required String label,
    required VoidCallback onPressed,
    IconData? icon,
    String? imagePath,
  }) {
    return InkWell(
      onTap: onPressed,
      borderRadius: BorderRadius.circular(15),
      child: Card(
        elevation: 2,
        color: primaryColor,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
        child: Padding(
          padding: const EdgeInsets.all(8.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              if (imagePath != null)
                Image.asset(imagePath, height: 120, fit: BoxFit.contain)
              else if (icon != null) ...[
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 13),
                  child: Icon(icon, size: 80, color: surfaceColor),
                ),
                vertGap(10),
              ],

              Text(
                label,
                textAlign: TextAlign.center,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: surfaceColor,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
