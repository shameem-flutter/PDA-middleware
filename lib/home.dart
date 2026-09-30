import 'dart:developer';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_nav_bar/google_nav_bar.dart';
import 'package:material_symbols_icons/symbols.dart';
import 'package:pda/constants/color_constants.dart';
import 'package:pda/providers/navigation_provider.dart';
import 'package:pda/providers/providers.dart';
import 'package:pda/screens/main_homepage.dart';
import 'package:pda/screens/product_catalog.dart';
import 'package:pda/screens/reviewscreen.dart';
import 'package:pda/screens/scanningscreen.dart';
import 'package:pda/utilities/width_calculator.dart';

final isSubmittingProvider = StateProvider<bool>((ref) => false);

class Home extends ConsumerStatefulWidget {
  final int initialIndex;
  const Home({super.key, this.initialIndex = 0});

  @override
  ConsumerState<Home> createState() => _HomeState();
}

class _HomeState extends ConsumerState<Home> {
  late final List<Widget> _screens;
  final PageStorageBucket _bucket = PageStorageBucket();
  late final int _initialIndex;
  bool _hasNavigatedAway = false;

  @override
  void initState() {
    super.initState();
    _initialIndex = widget.initialIndex;
    log('Home: initState, initialIndex: $_initialIndex');
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(navbarIndexProvider.notifier).state = _initialIndex;
    });
    _screens = [
      const MyHomePage(key: PageStorageKey('PDA'), usePushNavigation: false),
      const ProductCatalogScreen(key: PageStorageKey('ProductCatalog')),
      const ScanningScreen(key: PageStorageKey('ScanBarcode')),
      const ReviewCount(key: PageStorageKey('ReviewCount')),
    ];
  }

  Future<bool> _handleBackButton() async {
    final currentIndex = ref.read(navbarIndexProvider);
    log(
      'Home: _handleBackButton called, currentIndex: $currentIndex, initialIndex: $_initialIndex, hasNavigatedAway: $_hasNavigatedAway',
    );

    // If user hasn't navigated away from initial screen, always pop back to MyHomePage
    if (!_hasNavigatedAway && currentIndex == _initialIndex) {
      log('Home: User on initial screen, ALLOWING POP to MyHomePage');
      return true;
    }

    // If not on first tab, go to first tab
    if (currentIndex != 0) {
      log('Home: Switching to tab 0');
      ref.read(navbarIndexProvider.notifier).state = 0;
      _hasNavigatedAway = true;
      return false;
    } else {
      // On first tab after navigation, allow pop to MyHomePage
      log('Home: On first tab after navigation, ALLOWING POP to MyHomePage');
      return true; // Allow pop
    }
  }

  Future<void> _handleSubmit(BuildContext context) async {
    ref.read(isSubmittingProvider.notifier).state = true;
    final messenger = ScaffoldMessenger.of(context);
    try {
      final result = await ref
          .read(sessionsNotifierProvider.notifier)
          .submitToErp();

      if (!mounted) return;

      final message = result['message']?.toString() ?? '';
      final skippedProducts =
          (result['skippedProducts'] as List<dynamic>?)
              ?.map((e) => e.toString())
              .toList() ??
          [];
      final isSuccess = result['success'] as bool? ?? false;

      Color snackBarColor;
      if (!isSuccess) {
        snackBarColor = errorColor;
      } else if (skippedProducts.isEmpty) {
        snackBarColor = successColor;
      } else {
        snackBarColor = Colors.orange;
      }

      String displayMessage = message;
      if (skippedProducts.isNotEmpty) {
        displayMessage +=
            "\nSkipped ${skippedProducts.length} products: ${skippedProducts.join(', ')}";
      }

      messenger.showSnackBar(
        SnackBar(
          content: Text(displayMessage),
          backgroundColor: snackBarColor,
          duration: const Duration(seconds: 2),
        ),
      );

      if (isSuccess) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (mounted) {
            ref.read(navbarIndexProvider.notifier).state = 1;
          }
        });
      }
    } finally {
      if (mounted) ref.read(isSubmittingProvider.notifier).state = false;
    }
  }

  Widget _buildNavigationBody() {
    final navBarIndex = ref.watch(navbarIndexProvider);
    final isSubmitting = ref.watch(isSubmittingProvider);
    final bool isReviewScreen = navBarIndex == 3;
    final isWide = isWidthGreaterThan400(context);

    Widget buildBody() {
      return PageStorage(
        bucket: _bucket,
        child: IndexedStack(index: navBarIndex, children: _screens),
      );
    }

    Widget? navWidget;
    if (isWide) {
      navWidget = Scaffold(
        resizeToAvoidBottomInset: false,
        body: Row(
          children: [
            NavigationRail(
              selectedIndex: navBarIndex,
              onDestinationSelected: (value) {
                ref.read(navbarIndexProvider.notifier).state = value;
                _hasNavigatedAway = true;
              },
              destinations: [
                NavigationRailDestination(
                  icon: Icon(Icons.home_filled),
                  label: Text("Home"),
                ),
                NavigationRailDestination(
                  icon: Icon(Symbols.data_table),
                  label: Text("Catalog"),
                ),
                NavigationRailDestination(
                  icon: Icon(Icons.qr_code_scanner),
                  label: Text("data"),
                ),
                NavigationRailDestination(
                  icon: Icon(Icons.shopping_cart),
                  label: Text("Review"),
                ),
              ],
            ),
            Expanded(child: buildBody()),
          ],
        ),
      );
    } else {
      navWidget = Scaffold(
        body: buildBody(),
        floatingActionButtonLocation: FloatingActionButtonLocation.centerFloat,
        floatingActionButton: isReviewScreen
            ? FloatingActionButton(
                onPressed: isSubmitting
                    ? null
                    : () async {
                        final confirm = await showDialog<bool>(
                          context: context,
                          builder: (ctx) => AlertDialog(
                            title: const Text("Submit To ERP?"),
                            actions: [
                              TextButton(
                                onPressed: () => Navigator.pop(ctx, false),
                                child: const Text("Cancel"),
                              ),
                              TextButton(
                                onPressed: () => Navigator.pop(ctx, true),
                                child: const Text("Submit"),
                              ),
                            ],
                          ),
                        );

                        if (!mounted) return;

                        if (confirm == true) {
                          await _handleSubmit(context);
                        }
                      },
                backgroundColor: isSubmitting ? Colors.grey : primaryColor,
                child: isSubmitting
                    ? const CircularProgressIndicator(color: Colors.white)
                    : const Icon(Icons.cloud, color: Colors.white),
              )
            : null,
        bottomNavigationBar: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
          child: SafeArea(
            child: GNav(
              haptic: true,
              selectedIndex: navBarIndex,
              onTabChange: (value) {
                log('Home: GNav selected index: $value');
                final currentIndex = ref.read(navbarIndexProvider);
                if (currentIndex != value) {
                  ref.read(navbarIndexProvider.notifier).state = value;
                  _hasNavigatedAway = true;
                }
                if (value == 2) {
                  ref.read(scanRequestProvider.notifier).state = true;
                }
              },
              gap: 8,
              tabBackgroundColor: primaryColor,
              activeColor: Colors.white,
              color: primaryColor,
              padding: const EdgeInsets.all(16),
              style: GnavStyle.google,
              tabs: const [
                GButton(icon: Icons.home_filled),
                GButton(icon: Symbols.data_table),
                GButton(icon: Icons.qr_code_scanner_rounded),
                GButton(icon: Icons.shopping_cart),
              ],
            ),
          ),
        ),
      );
    }
    return navWidget;
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, result) async {
        if (didPop) return;
        log('===== Home: WillPopScope onWillPop CALLED =====');
        log('Home: navBarIndex: ${ref.read(navbarIndexProvider)}');
        log(
          'Home: _initialIndex: $_initialIndex, _hasNavigatedAway: $_hasNavigatedAway',
        );

        final shouldPop = await _handleBackButton();
        log('Home: shouldPop result: $shouldPop');

        if (shouldPop && context.mounted) {
          Navigator.of(context).pop();
        }
      },
      child: _buildNavigationBody(),
    );
  }
}
