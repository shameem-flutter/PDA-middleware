import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:pda/screens/reviewscreen.dart';
import 'package:pda/screens/splashscreen.dart';
import 'package:pda/services/api_services/scanning_service.dart';
import 'package:pda/utilities/scanhandler.dart';

import 'package:pda/utilities/print_function.dart';

final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();

void main() {
  runZonedGuarded(() async {
    WidgetsFlutterBinding.ensureInitialized();

    // 1. Catch Flutter framework errors
    FlutterError.onError = (FlutterErrorDetails details) {
      FlutterError.presentError(details);
      printOrLog("⚠️ Uncaught Flutter Error: ${details.exceptionAsString()} \n${details.stack}");
      // Telemetry hook for future Crashlytics/Sentry integration:
      // FirebaseCrashlytics.instance.recordFlutterError(details);
    };

    // 2. Catch asynchronous platform errors
    PlatformDispatcher.instance.onError = (Object error, StackTrace stack) {
      printOrLog("🔴 Uncaught Platform/Async Error: $error \n$stack");
      // Telemetry hook for future Crashlytics/Sentry integration:
      // FirebaseCrashlytics.instance.recordError(error, stack, fatal: true);
      return true; // Prevents crash
    };

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
  }, (error, stack) {
    printOrLog("🔴 Uncaught Zone Error: $error \n$stack");
  });
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
      messenger = ScaffoldMessenger.maybeOf(context);

      _scanSubscription = scannerService.scanStream.listen((code) async {
        printOrLog("Global scanned code: $code");
        if (mounted) {
          final ctx = navigatorKey.currentContext;
          if (ctx != null && messenger != null) {
            await handleScannedCode(messenger!, code, ref);
          } else {
            printOrLog("no context available for handling scanned code");
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
