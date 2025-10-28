import 'package:flutter_riverpod/flutter_riverpod.dart';

final navbarIndexProvider = StateProvider<int>((ref) => 0);

final tabNavigationProvider = Provider<TabNavigation>((ref) {
  return TabNavigation(ref);
});

class TabNavigation {
  final Ref ref;

  TabNavigation(this.ref);

  void switchTab(int index) {
    ref.read(navbarIndexProvider.notifier).state = index;
  }

  void switchToReview() => switchTab(3);
  void switchToScan() => switchTab(2);
  void switchToCatalog() => switchTab(1);
  void switchToMyHome() => switchTab(0);
}
