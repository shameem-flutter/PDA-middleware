import 'dart:async';
import 'dart:developer';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:pda/screens/reviewscreen.dart';
import 'package:pda/screens/splashscreen.dart';
import 'package:pda/services/api_services/scanning_service.dart';
import 'package:pda/utilities/scanhandler.dart';
import 'package:pda/utilities/width_calculator.dart';

final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const ProviderScope(child: PDA()));
}

class PDA extends ConsumerStatefulWidget {
  const PDA({super.key});

  @override
  ConsumerState<PDA> createState() => _PDAState();
}

class _PDAState extends ConsumerState<PDA> {
  late ScannerService scannerService;
  StreamSubscription<String>? _scanSubscription;

  @override
  void initState() {
    final messenger = ScaffoldMessenger.of(context);
    super.initState();
    scannerService = ScannerService();
    _scanSubscription = scannerService.scanStream.listen((code) async {
      log("Global scanned code: $code");
      if (mounted) {
        final context = navigatorKey.currentContext;

        if (context != null) {
          await handleScannedCode(messenger, code, ref);
        } else {
          log("no context available for handling scanned code");
        }
      }
    });
  }

  @override
  void dispose() {
    _scanSubscription?.cancel();
    scannerService.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      navigatorKey: navigatorKey,
      debugShowCheckedModeBanner: false,
      home: const SplashScreen(),
      routes: {'/review': (context) => const ReviewCount()},
      theme: ThemeData(
        useMaterial3: true,
        scaffoldBackgroundColor: Colors.white,
        appBarTheme: AppBarTheme(
          titleSpacing: 30,
          centerTitle: false,
          backgroundColor: Colors.white,
          surfaceTintColor: Colors.transparent,
          actionsPadding: EdgeInsets.only(
            right: isWidthGreaterThan400(context) || kIsWeb ? 40 : 0,
          ),
        ),
        bottomNavigationBarTheme: const BottomNavigationBarThemeData(
          backgroundColor: Colors.white,
        ),
      ),
    );
  }
}
