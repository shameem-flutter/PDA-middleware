import 'dart:async';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:device_info_plus/device_info_plus.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:flutter_datawedge/flutter_datawedge.dart';
import 'package:pda/providers/navigation_provider.dart';
import 'package:pda/providers/providers.dart';
import 'package:pda/utilities/scanhandler.dart';
import 'package:pda/utilities/width_calculator.dart';
import 'package:pda/widgets/customappbartitle.dart';
import 'package:pda/widgets/custombutton.dart';

class ScanningScreen extends ConsumerStatefulWidget {
  const ScanningScreen({super.key});

  @override
  ConsumerState<ScanningScreen> createState() => _ScanningScreenState();
}

class _ScanningScreenState extends ConsumerState<ScanningScreen>
    with SingleTickerProviderStateMixin, WidgetsBindingObserver {
  MobileScannerController? _cameraController;
  late final AnimationController _animationController;
  late final Animation<double> _animation;
  bool isScanned = false;
  bool _useHardwareScanner = false;
  bool _isControllerInitialized = false;
  StreamSubscription? _scanRequestSub;

  // ✅ NEW: Track camera state
  bool _isCameraStarted = false;
  // bool _widgetBuilt = false;

  // PDA Scanner variables
  String _scannedBuffer = '';
  final FocusNode _focusNode = FocusNode();
  Timer? _bufferTimer;
  String _deviceManufacturer = '';
  final FlutterDataWedge _dataWedge = FlutterDataWedge();
  StreamSubscription<ScanResult>? _dwSubscription;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);

    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    )..repeat();
    _animation = Tween<double>(begin: 0, end: 1).animate(_animationController);
    _detectScanner();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    super.didChangeAppLifecycleState(state);

    if (state == AppLifecycleState.resumed) {
      if (_useHardwareScanner) {
        _focusNode.requestFocus();
        if (_deviceManufacturer.contains('zebra')) {
          _reinitializeDataWedge();
        }
      }
    } else if (state == AppLifecycleState.paused) {
      if (!_useHardwareScanner && _isCameraStarted) {
        _cameraController?.stop();
        _isCameraStarted = false;
      }
    }
  }

  Future<void> _detectScanner() async {
    if (!Platform.isAndroid) {
      setState(() {
        _useHardwareScanner = false;
        _isControllerInitialized = true;
      });
      await _initCamera();
      return;
    }

    try {
      final deviceInfo = DeviceInfoPlugin();
      final android = await deviceInfo.androidInfo;
      final manu = android.manufacturer.toLowerCase();
      _deviceManufacturer = manu;

      debugPrint("📱 Device Manufacturer: $manu");
      debugPrint("📱 Device Model: ${android.model}");

      final useHardware =
          manu.contains('sunmi') ||
          manu.contains('zebra') ||
          manu.contains('honeywell') ||
          manu.contains('elyctis');

      setState(() {
        _useHardwareScanner = useHardware;
        _isControllerInitialized = true;
      });

      if (_useHardwareScanner) {
        // PDA SCANNER SETUP
        if (manu.contains('zebra')) {
          await _initializeDataWedge();
        } else {
          _listenToHardwareScanner();
          debugPrint("✅ Using hardware keyboard scanner for $manu");
        }
        WidgetsBinding.instance.addPostFrameCallback((_) {
          _focusNode.requestFocus();
        });
      } else {
        // MOBILE CAMERA SETUP
        await _initCamera();
      }
    } catch (e) {
      debugPrint("❌ Scanner detect error: $e");
      setState(() {
        _useHardwareScanner = false;
        _isControllerInitialized = true;
      });
      await _initCamera();
    }
  }

  // ========== PDA SCANNER CODE (DON'T CHANGE) ==========
  Future<void> _initializeDataWedge() async {
    try {
      await _dataWedge.initialize();
      debugPrint("✅ DataWedge initialized");

      await _dataWedge.createDefaultProfile(profileName: 'PDAProfile');
      debugPrint("✅ DataWedge profile created");

      _dwSubscription = _dataWedge.onScanResult.listen(
        (scanResult) {
          if (!mounted || isScanned) return;
          final code = scanResult.data.trim();
          if (code.isNotEmpty && !isScanned) {
            debugPrint("📡 Zebra Scan Detected: $code");
            _onCodeDetected(code);
          }
        },
        onError: (e) {
          debugPrint("❌ DataWedge scan error: $e");
        },
      );

      debugPrint("✅ DataWedge listening for scans");
    } catch (e) {
      debugPrint("❌ Failed to initialize DataWedge: $e");
      _listenToHardwareScanner();
    }
  }

  Future<void> _reinitializeDataWedge() async {
    await _dwSubscription?.cancel();
    await _initializeDataWedge();
  }

  void _listenToHardwareScanner() {
    HardwareKeyboard.instance.addHandler(_onKeyEvent);
    debugPrint("✅ Hardware scanner listener active");
  }

  bool _onKeyEvent(KeyEvent event) {
    if (event is! KeyDownEvent) return false;

    final keyLabel = event.logicalKey.keyLabel;

    if (keyLabel == 'Enter' || event.logicalKey == LogicalKeyboardKey.enter) {
      _bufferTimer?.cancel();
      if (_scannedBuffer.isNotEmpty && !isScanned) {
        final code = _scannedBuffer.trim();
        debugPrint("🔍 Hardware Barcode Detected: $code");
        _scannedBuffer = '';
        _onCodeDetected(code);
      }
      return true;
    }

    if (keyLabel.isNotEmpty && keyLabel.length == 1) {
      _scannedBuffer += keyLabel;
      _bufferTimer?.cancel();
      _bufferTimer = Timer(const Duration(milliseconds: 200), () {
        if (!mounted) return;
        if (_scannedBuffer.isNotEmpty && !isScanned) {
          final code = _scannedBuffer.trim();
          if (code.length >= 8) {
            debugPrint("🔍 Hardware Barcode Detected (timeout): $code");
            _scannedBuffer = '';
            _onCodeDetected(code);
          }
        }
      });
      return true;
    }

    return false;
  }

  void _stopListeningHardwareScanner() {
    HardwareKeyboard.instance.removeHandler(_onKeyEvent);
    _bufferTimer?.cancel();
  }
  // ========== END PDA SCANNER CODE ==========

  // ✅ MOBILE CAMERA CODE - FIXED
  Future<void> _initCamera() async {
    _cameraController ??= MobileScannerController(
      autoStart: false,
      detectionSpeed: DetectionSpeed.noDuplicates,
    );
    debugPrint("✅ Camera controller initialized");
  }

  Future<void> _startScanner() async {
    if (_useHardwareScanner || !_isControllerInitialized) return;

    // ✅ Prevent multiple starts
    if (_isCameraStarted) {
      debugPrint("⚠️ Camera already started");
      return;
    }

    try {
      if (_cameraController != null && !isScanned) {
        await _cameraController!.start();
        setState(() {
          _isCameraStarted = true;
        });
        debugPrint("✅ Camera started successfully");
      }
    } catch (e) {
      debugPrint("❌ Error starting scanner: $e");
      setState(() {
        _isCameraStarted = false;
      });
    }
  }

  void _onDetect(BarcodeCapture capture) {
    if (isScanned) return;
    final code = capture.barcodes.first.rawValue;
    if (code != null) _onCodeDetected(code);
  }

  Future<void> _onCodeDetected(String code) async {
    final messenger = ScaffoldMessenger.of(context);
    if (isScanned) return;
    if (!mounted) return;
    setState(() => isScanned = true);
    debugPrint("🎯 Processing barcode: $code");

    // ✅ Stop camera immediately for mobile
    if (!_useHardwareScanner && _isCameraStarted) {
      await _cameraController?.stop();
      _isCameraStarted = false;
      debugPrint("✅ Camera stopped after scan");
    }

    if (_useHardwareScanner) {
      // PDA handling

      await handleScannedCode(messenger, code, ref);
      if (mounted) {
        ref.read(tabNavigationProvider).switchToReview();
        ref.read(sessionsNotifierProvider.notifier).loadSessions();
      }
    } else {
      // Mobile camera handling
      final dbHelper = ref.read(dbProvider);
      final product = await dbHelper.getProductByBarcode(code);

      if (!mounted) return;

      if (product != null) {
        await dbHelper.insertOrUpdateProduct(product);
        final existingSession = await dbHelper.getCountingSessionByProductId(
          product.id!,
        );
        int newCount = 1;
        if (existingSession != null) {
          newCount = existingSession.countedQuantity + 1;
          await ref
              .read(sessionsNotifierProvider.notifier)
              .updateSession(product.id!, newCount);
        } else {
          await ref
              .read(sessionsNotifierProvider.notifier)
              .createSession(product.id!, newCount);
        }
        if (mounted) {
          ref.read(tabNavigationProvider).switchToReview();
        }
      } else {
        // ✅ Product not found — show snackbar and go to Catalog
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: const Text(
                "❌ Product not found — returning to catalog",
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              backgroundColor: Colors.redAccent,
              duration: const Duration(seconds: 1),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.all(Radius.circular(10)),
              ),
              behavior: SnackBarBehavior.floating,
            ),
          );

          // Wait briefly, then go to Catalog screen
          await Future.delayed(const Duration(seconds: 1));
          if (mounted) {
            ref.read(tabNavigationProvider).switchToCatalog();
          }
        }
      }
    }

    // ✅ Reset scan state
    if (mounted) {
      setState(() => isScanned = false);
      if (_useHardwareScanner) {
        _focusNode.requestFocus();
      }
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _scanRequestSub?.cancel();
    _dwSubscription?.cancel();
    _stopListeningHardwareScanner();
    _bufferTimer?.cancel();
    _cameraController?.stop();
    _cameraController?.dispose();
    _animationController.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // ✅ Mark widget as built after first frame

    // Navigation listener
    ref.listen<int>(navbarIndexProvider, (prev, next) async {
      if (!mounted) return;
      if (next != 2) {
        // Not on scanning tab - stop camera
        if (_isCameraStarted) {
          await _cameraController?.stop();
          if (!mounted) return;
          setState(() {
            _isCameraStarted = false;
          });

          debugPrint("✅ Camera stopped (tab changed)");
        }
      } else if (next == 2 &&
          !_useHardwareScanner &&
          _isControllerInitialized) {
        // On scanning tab - start camera
        await Future.delayed(const Duration(milliseconds: 100));
        if (mounted && !_isCameraStarted) {
          await _startScanner();
        }
      }
    });

    // Scan request listener
    ref.listen(scanRequestProvider, (previous, next) async {
      if (!mounted) return;
      if (next && !_useHardwareScanner && _isControllerInitialized) {
        await Future.delayed(const Duration(milliseconds: 100));
        if (mounted && !_isCameraStarted) {
          await _startScanner();
        }
        if (mounted) {
          ref.read(scanRequestProvider.notifier).state = false;
        }
      }
    });

    double scannerHeight = 300.0;
    double scannerWidth = MediaQuery.of(context).size.width - 48;

    return KeyboardListener(
      focusNode: _focusNode,
      autofocus: _useHardwareScanner,
      onKeyEvent: _useHardwareScanner ? (event) {} : null,
      child: Scaffold(
        persistentFooterButtons: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              CustomButton(
                text: "Cancel",
                onPressed: () async {
                  if (_isCameraStarted) {
                    await _cameraController?.stop();
                    if (!mounted) return;
                    setState(() {
                      _isCameraStarted = false;
                    });
                    debugPrint("camera stopped by cancel button");
                  }
                  final currentIndex = ref.read(navbarIndexProvider);
                  if (currentIndex == 2) {
                    ref.read(tabNavigationProvider).switchToCatalog();
                  } else if (currentIndex == 3) {
                    ref.read(tabNavigationProvider).switchToReview();
                  }
                },
                padding: const EdgeInsets.symmetric(
                  horizontal: 15,
                  vertical: 12,
                ),
              ),
            ],
          ),
        ],
        appBar: AppBar(
          title: const CustomAppBarTitle(title: "Scan Barcode"),
          centerTitle: true,
          toolbarHeight: 80,
        ),
        body: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 15),
          child: GestureDetector(
            onTap: () {
              if (_useHardwareScanner) {
                _focusNode.requestFocus();
              }
            },
            child: LayoutBuilder(
              builder: (context, constraints) {
                return SingleChildScrollView(
                  child: ConstrainedBox(
                    constraints: BoxConstraints(
                      minHeight: constraints.minHeight,
                    ),
                    child: IntrinsicHeight(
                      child: Center(
                        child: Padding(
                          padding: EdgeInsets.symmetric(
                            horizontal: isWidthGreaterThan400(context)
                                ? 140
                                : 24,
                            vertical: 80,
                          ),
                          child: Container(
                            height: scannerHeight,
                            width: scannerWidth,
                            decoration: BoxDecoration(
                              border: Border.all(color: Colors.white, width: 2),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: ClipRRect(
                              borderRadius: BorderRadius.circular(12),
                              child: Stack(
                                children: [
                                  if (_useHardwareScanner)
                                    Center(
                                      child: Padding(
                                        padding: const EdgeInsets.all(20.0),
                                        child: Column(
                                          mainAxisAlignment:
                                              MainAxisAlignment.center,
                                          children: [
                                            Icon(
                                              Icons.qr_code_scanner,
                                              size: 80,
                                              color: Colors.blue.shade300,
                                            ),
                                            const SizedBox(height: 20),
                                            Text(
                                              "📡 Hardware Scanner Active",
                                              style: TextStyle(
                                                fontSize: 18,
                                                fontWeight: FontWeight.bold,
                                                color: Colors.blue.shade700,
                                              ),
                                              textAlign: TextAlign.center,
                                            ),
                                            const SizedBox(height: 10),
                                            Text(
                                              _deviceManufacturer.contains(
                                                    'zebra',
                                                  )
                                                  ? "Press the scan button"
                                                  : "Press the yellow scan button",
                                              style: const TextStyle(
                                                fontSize: 14,
                                              ),
                                              textAlign: TextAlign.center,
                                            ),
                                            const SizedBox(height: 10),
                                            Text(
                                              "Device: ${_deviceManufacturer.toUpperCase()}",
                                              style: TextStyle(
                                                fontSize: 12,
                                                color: Colors.grey.shade600,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                    )
                                  else if (_cameraController != null &&
                                      _isControllerInitialized)
                                    MobileScanner(
                                      controller: _cameraController!,
                                      onDetect: _onDetect,
                                      fit: BoxFit.cover,
                                    )
                                  else
                                    const Center(
                                      child: CircularProgressIndicator(),
                                    ),

                                  AnimatedBuilder(
                                    animation: _animation,
                                    builder: (context, child) {
                                      return Positioned(
                                        top:
                                            _animation.value *
                                            (scannerHeight - 2),
                                        left: 0,
                                        right: 0,
                                        child: Container(
                                          height: 4,
                                          color: Colors.blue.withValues(
                                            alpha: 0.6,
                                          ),
                                        ),
                                      );
                                    },
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
        ),
      ),
    );
  }
}
