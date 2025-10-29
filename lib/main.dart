import 'dart:async';
import 'dart:developer';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:pda/screens/reviewscreen.dart';
import 'package:pda/screens/splashscreen.dart';
import 'package:pda/services/api_services/scanning_service.dart';
import 'package:pda/utilities/scanhandler.dart';

final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(
    ProviderScope(
      child: MaterialApp(
        navigatorKey: navigatorKey,
        debugShowCheckedModeBanner: false,
        title: 'PDA Middleware',
        home: const PDA(),
        routes: {'/review': (context) => const ReviewCount()},
        theme: ThemeData(
          useMaterial3: true,
          scaffoldBackgroundColor: Colors.white,
          appBarTheme: AppBarTheme(
            titleSpacing: 30,
            centerTitle: false,
            backgroundColor: Colors.white,
            surfaceTintColor: Colors.transparent,
            actionsPadding: EdgeInsets.only(right: kIsWeb ? 40 : 0),
          ),
          bottomNavigationBarTheme: const BottomNavigationBarThemeData(
            backgroundColor: Colors.white,
          ),
        ),
      ),
    ),
  );
}

class PDA extends ConsumerStatefulWidget {
  const PDA({super.key});

  @override
  ConsumerState<PDA> createState() => _PDAState();
}

class _PDAState extends ConsumerState<PDA> {
  late ScannerService scannerService;
  StreamSubscription<String>? _scanSubscription;
  ScaffoldMessengerState? messenger;

  @override
  void initState() {
    super.initState();
    scannerService = ScannerService();

    // ✅ Schedule setup after the first frame (when context is fully ready)
    WidgetsBinding.instance.addPostFrameCallback((_) {
      messenger = ScaffoldMessenger.of(context);

      _scanSubscription = scannerService.scanStream.listen((code) async {
        log("Global scanned code: $code");
        if (mounted) {
          final ctx = navigatorKey.currentContext;
          if (ctx != null && messenger != null) {
            await handleScannedCode(messenger!, code, ref);
          } else {
            log("no context available for handling scanned code");
          }
        }
      });
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
    return const SplashScreen();
  }
}
