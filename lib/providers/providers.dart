import 'dart:io';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:pda/database/appdatabase.dart';
import 'package:pda/models/count_session.dart';
import 'package:pda/models/products.dart';
import 'package:pda/services/api_services/authservice.dart';
import 'package:pda/services/api_services/pda_services.dart';
import 'package:pda/services/api_services/submit_erp.dart';
import 'package:pda/services/secure_storage_service.dart';
import 'package:pda/utilities/print_function.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:developer';
import 'package:flutter/foundation.dart';
import 'package:pda/constants/apiclient.dart';

final sharedPrefsProvider = FutureProvider<SharedPreferences>((ref) async {
  final prefs = await SharedPreferences.getInstance();
  await prefs.reload();
  return prefs;
});
final isLoggingOutProvider = StateProvider<bool>((ref) => false);

// Database Helper Provider
final dbProvider = Provider<DatabaseHelper>((ref) => DatabaseHelper());

// Auth Service Provider
final authServiceProvider = Provider<Authservice>((ref) {
  return Authservice(ref.read(sharedPrefsProvider.future));
});

// Pda Services Provider
final pdaServicesProvider = Provider<PdaServices>((ref) {
  return PdaServices(
    ref.read(sharedPrefsProvider.future),
    ref.read(authServiceProvider),
  );
});

// In providers.dart - Replace the erpBackendProvider
final erpBackendProvider = FutureProvider<ErpBackend>((ref) async {
  final prefs = await ref.read(sharedPrefsProvider.future);
  final backend = prefs.getString('backend');

  if (backend == 'django') {
    log('✅ Backend: Django (from prefs)');
    return ErpBackend.django;
  }
  if (backend == 'odoo') {
    log('✅ Backend: Odoo (from prefs)');
    return ErpBackend.odoo;
  }

  // Default fallback — force login screen instead of guessing
  log("❌ No backend stored. User must login again.");
  return ErpBackend.django;
});

// Update the dynamic provider to use FutureProvider
final dynamicSubmitErpServiceProvider =
    AutoDisposeFutureProvider<SubmitErpService>((ref) async {
      final backend = await ref.watch(erpBackendProvider.future);
      log("🧭 Using backend for SubmitErpService: $backend");

      return SubmitErpService(
        prefs: ref.read(sharedPrefsProvider.future),
        authservice: ref.read(authServiceProvider),
        backend: backend,
      );
    });

// Auth State
class AuthState {
  final bool isLoading;
  final bool isLoggedIn;
  final String? userName;
  final String? erpUrl;
  final String? token;

  AuthState({
    required this.isLoading,
    required this.isLoggedIn,
    this.userName,
    this.erpUrl,
    this.token,
  });

  AuthState copyWith({
    bool? isLoading,
    bool? isLoggedIn,
    String? userName,
    String? erpUrl,
    String? token,
  }) {
    return AuthState(
      isLoading: isLoading ?? this.isLoading,
      isLoggedIn: isLoggedIn ?? this.isLoggedIn,
      userName: userName ?? this.userName,
      erpUrl: erpUrl ?? this.erpUrl,
      token: token ?? this.token,
    );
  }
}

// Auth Notifier
class AuthNotifier extends Notifier<AuthState> {
  @override
  AuthState build() {
    _checkAuthenticationStatus();
    return AuthState(isLoading: false, isLoggedIn: false);
  }

  Future<void> _restoreSessionCookie() async {
    final prefs = await ref.read(sharedPrefsProvider.future);
    final secureStorage = SecureStorageService();
    final token = await secureStorage.read(SecureStorageService.keyToken, prefs: prefs);
    final sessionId = await secureStorage.read(SecureStorageService.keySessionId, prefs: prefs);
    final erpUrl = prefs.getString("erp_url");

    if (erpUrl == null) {
      printOrLog("No erp URL in sharedpreferences.cannot restore auth");
      return;
    }
    final uri = Uri.parse(erpUrl);

    if (token != null && token.isNotEmpty) {
      final cookie = Cookie("token", token);
      ApiClient.cookieJar.saveFromResponse(uri, [cookie]);
      printOrLog("✅ Restored token into CookieJar");
    } else if (sessionId != null && sessionId.isNotEmpty) {
      final sessionCookie = Cookie("session_id", sessionId);
      await ApiClient.cookieJar.saveFromResponse(uri, [sessionCookie]);
      printOrLog("restored odoo session_id");
    } else {
      printOrLog("⚠️ No session cookie found.");
    }
  }

  Future<void> _checkAuthenticationStatus() async {
    printOrLog("🔍 Checking authentication status...");

    final prefs = await ref.read(sharedPrefsProvider.future);
    final secureStorage = SecureStorageService();
    final token = await secureStorage.read(SecureStorageService.keyToken, prefs: prefs);
    final erpUrl = prefs.getString("erp_url");
    final userName = prefs.getString("username");
    final sessionId = await secureStorage.read(SecureStorageService.keySessionId, prefs: prefs);
    final backend = prefs.getString("backend");

    final hasCredentials =
        (token != null && token.isNotEmpty) ||
        (sessionId != null && sessionId.isNotEmpty);

    // ✅ If no credentials or no URL, definitely not logged in
    if (!hasCredentials || erpUrl == null) {
      printOrLog("❌ No valid credentials found");
      state = state.copyWith(
        isLoggedIn: false,
        userName: null,
        erpUrl: null,
        isLoading: false,
      );
      return;
    }

    // ✅ Additional validation: Check if we have backend info
    if (backend == null || backend.isEmpty) {
      printOrLog("❌ Backend info missing — stale session. Clearing and logging out");

      await prefs.clear();
      await secureStorage.deleteAll(prefs: prefs);
      await ApiClient.cookieJar.deleteAll();

      state = state.copyWith(
        isLoggedIn: false,
        userName: null,
        erpUrl: null,
        isLoading: false,
      );
      return;
    }

    // ✅ Restore session
    await _restoreSessionCookie();

    log("✅ Valid session found - user is logged in");
    log("   Backend: $backend");
    log("   User: $userName");
    log("   URL: $erpUrl");

    state = state.copyWith(
      isLoggedIn: true,
      userName: userName,
      erpUrl: erpUrl,
      isLoading: false,
    );
  }

  Future<bool> login({
    required String username,
    required String db,
    required String password,
    required String baseUrl,
  }) async {
    try {
      state = state.copyWith(isLoading: true);

      final prefs = await ref.read(sharedPrefsProvider.future);
      final oldBackend = prefs.getString('backend');

      final authService = ref.read(authServiceProvider);
      final success = await authService.login(
        username: username,
        db: db,
        password: password,
        baseUrl: baseUrl,
      );

      if (db.isNotEmpty) {
        await prefs.setString("organization_id", db);
      }

      if (success) {
        ref.read(isLoggingOutProvider.notifier).state = false;
      }

      if (!success) {
        log("Login failed: Invalid credentials or server error");
        state = state.copyWith(isLoading: false);
        return false;
      }

      final newBackend = success ? prefs.getString('backend') : null;

      if (oldBackend != null &&
          newBackend != null &&
          oldBackend != newBackend) {
        log('backend Switched $oldBackend to $newBackend, clearing local db');
        final dbHelper = ref.read(dbProvider);
        await dbHelper.clearCountingSessions();
        await dbHelper.clearProducts();
        ref.read(sessionsNotifierProvider.notifier).reset();
        ref.invalidate(productsNotifierProvider);
      }

      final token = prefs.getString("token");
      final sessionId = prefs.getString("session_id");
      if ((token == null || token.isEmpty) &&
          (sessionId == null || sessionId.isEmpty)) {
        log("Login succeeded but token is missing in SharedPreferences");
        state = state.copyWith(isLoading: false);
        return false;
      }

      if (token != null && token.isNotEmpty) {
        log(
          "loggin successfull with django token ${token.substring(0, 20)}...",
        );
      } else if (sessionId != null && sessionId.isNotEmpty) {
        log(
          "Loggin successfull with odoo session_id ${sessionId.substring(0, 30)}",
        );
      }

      // Save user info in prefs
      await prefs.setString("username", username);
      if (db.isNotEmpty) {
        await prefs.setString("organization_id", db);
      }
      log("Login successful with  token: $token");

      // Optionally trigger product sync

      ref.invalidate(sessionsNotifierProvider);
      ref.invalidate(productsNotifierProvider);
      await ref.read(productsNotifierProvider.notifier).syncProducts();

      state = state.copyWith(
        isLoggedIn: true,
        userName: username,
        erpUrl: baseUrl,
        isLoading: false,
      );

      return true;
    } catch (e, st) {
      log("Login error: $e", stackTrace: st);
      state = state.copyWith(isLoading: false);
      return false;
    }
  }

  Future<void> logout() async {
    final dbHelper = ref.read(dbProvider);

    await dbHelper.clearCountingSessions();
    await dbHelper.clearProducts();
    ref.read(isLoggingOutProvider.notifier).state = true;
    ref.read(sessionsNotifierProvider.notifier).reset();

    ref.invalidate(sessionsNotifierProvider);
    ref.invalidate(productsNotifierProvider);
    ref.invalidate(erpBackendProvider);
    ref.invalidate(dynamicSubmitErpServiceProvider);

    final prefs = await ref.read(sharedPrefsProvider.future);
    await prefs.remove('backend');

    await ref.read(authServiceProvider).logOut();
    state = state.copyWith(isLoggedIn: false, userName: null, erpUrl: null);
  }
}

final authNotifierProvider = NotifierProvider<AuthNotifier, AuthState>(
  () => AuthNotifier(),
);

// Products Notifier
class ProductsNotifier extends AsyncNotifier<List<Product>> {
  @override
  Future<List<Product>> build() async {
    return _loadProducts();
  }

  Future<List<Product>> _loadProducts() async {
    final dbHelper = ref.read(dbProvider);
    final pdaServices = ref.read(pdaServicesProvider);
    final isLoggingOut = ref.read(isLoggingOutProvider);
    if (isLoggingOut) {
      log("⛔ Logout in progress — skip product loading");
      return state.value ?? []; // keep existing list
    }

    try {
      final response = await pdaServices.getAllPda();

      if (response == null || response.statusCode != 200) {
        final cached = await dbHelper.getProducts();
        if (cached.isNotEmpty) return cached;
        throw Exception('Failed to load products');
      }

      List<Product> productsFromApi = [];

      if (response.data is Map<String, dynamic>) {
        final jsonData = response.data as Map<String, dynamic>;

        // ✅ Odoo format (data inside "result")
        if (jsonData.containsKey("result") && jsonData["result"] is List) {
          final List<dynamic> resultList = jsonData["result"];

          productsFromApi = resultList.map((item) {
            return Product.fromApi({
              "id": item["product_id"],
              "name": item["product_name"] ?? "Unknown",
              "barcode": item["barcode"] ?? "",
              "product_id": item["reference"] ?? "",
              "erp_quantity": (item["available_qty"] ?? 0).toInt(),
            });
          }).toList();

          printOrLog("✅ Parsed ${productsFromApi.length} Odoo products");
        }
        // ✅ Django format (data inside "data")
        else if (jsonData.containsKey("data") && jsonData["data"] is List) {
          final List<dynamic> itemsList = jsonData["data"];
          productsFromApi = itemsList
              .map((item) => Product.fromApi(item as Map<String, dynamic>))
              .toList();
          printOrLog("✅ Parsed ${productsFromApi.length} Django products");


        }
      }

      // ✅ Save to local DB
      if (productsFromApi.isNotEmpty) {
        await dbHelper.syncProducts(productsFromApi);
      }

      return productsFromApi;
    } catch (e, st) {
      printOrLog("⚠️ Error loading products (maybe logging out): $e");

      final cached = await dbHelper.getProducts();
      if (cached.isNotEmpty) return cached;

      // If user is logging out, do not throw UI errors
      final prefs = await ref.read(sharedPrefsProvider.future);
      final backend = prefs.getString("backend");
      if (backend == null) {
        printOrLog("⛔ Skip product error — user logged out");
        return [];
      }

      state = AsyncError(e, st);
      rethrow;
    }
  }

  Future<void> syncProducts() async {
    final prefs = await ref.read(sharedPrefsProvider.future);
    final backend = prefs.getString("backend");
    final isOdoo = backend == 'odoo';

    try {
      if (isOdoo) {
        state = const AsyncLoading<List<Product>>().copyWithPrevious(state);
      }

      final products = await _loadProducts();
      state = AsyncData(products); // only set data, not loading
    } catch (e, st) {
      state = AsyncError(e, st);
    }
  }
}

final productsNotifierProvider =
    AsyncNotifierProvider<ProductsNotifier, List<Product>>(
      ProductsNotifier.new,
    );

// Search Query Provider
final searchQueryProvider = StateProvider<String>((ref) => '');

// Filtered Products Provider
final filteredProductsProvider = Provider<List<Product>>((ref) {
  final asyncProducts = ref.watch(productsNotifierProvider);
  final rawQuery = ref.watch(searchQueryProvider);

  final products = asyncProducts.value ?? [];
  final cleanQuery = rawQuery.trim().toLowerCase();
  if (cleanQuery.isEmpty) return products;

  return products.where((p) {
    final name = p.name.toLowerCase();
    final barcode = (p.barcode ?? '').toLowerCase();
    final productId = (p.productId ?? '').toLowerCase();
    final sku = p.sku.toLowerCase();

    return name.contains(cleanQuery) ||
        barcode.contains(cleanQuery) ||
        productId.contains(cleanQuery) ||
        sku.contains(cleanQuery);
  }).toList();
});

// Sessions Notifier
class SessionsNotifier extends AsyncNotifier<List<CountingSession>> {
  @override
  Future<List<CountingSession>> build() async {
    final dbHelper = ref.read(dbProvider);
    return await dbHelper.getCountingSessions();
  }

  // New: Add loadSessions to refresh sessions
  Future<void> loadSessions() async {
    // state = const AsyncLoading();
    try {
      final dbHelper = ref.read(dbProvider);
      state = AsyncData(await dbHelper.getCountingSessions());
    } catch (e, st) {
      state = AsyncError(e, st);
    }
  }

  Future<void> createSession(int productId, int countedQuantity) async {
    try {
      final dbHelper = ref.read(dbProvider);
      final product = await dbHelper.getProductById(productId);
      if (product == null) {
        throw Exception('Product not found for ID: $productId');
      }
      final session = CountingSession(
        productId: productId,
        productName: product.name,
        countedQuantity: countedQuantity,
        erpQuantity: product.erpQuantity,
      );
      await dbHelper.insertCountingSession(session);
      state = AsyncData(await dbHelper.getCountingSessions());
    } catch (e, st) {
      state = AsyncError(e, st);
    }
  }

  Future<void> updateSession(int productId, int newQty) async {
    try {
      final dbHelper = ref.read(dbProvider);
      await dbHelper.updateCountingSession(productId, newQty);
      state = AsyncData(await dbHelper.getCountingSessions());
    } catch (e, st) {
      state = AsyncError(e, st);
    }
  }

  // Replace your deleteSession method in SessionsNotifier with this:

  Future<void> deleteSession(int id) async {
    debugPrint("🔍 SessionsNotifier: Starting delete for session id: $id");

    try {
      final dbHelper = ref.read(dbProvider);

      // ✅ Get current sessions before deletion
      final currentSessions = state.value ?? [];
      debugPrint("📊 Current sessions count: ${currentSessions.length}");

      // ✅ Verify the session exists in current state
      final sessionToDelete = currentSessions.firstWhere(
        (s) => s.id == id,
        orElse: () => throw Exception("Session id: $id not found in state"),
      );

      debugPrint("✅ Found session to delete: ${sessionToDelete.productName}");

      // ✅ Delete from database
      final result = await dbHelper.deleteCountingSession(id);

      if (result == 0) {
        debugPrint("⚠️ No rows deleted for session id: $id");
        throw Exception("Failed to delete session id: $id");
      }

      debugPrint("✅ Successfully deleted session id: $id from database");

      // ✅ Refresh state from database
      final updatedSessions = await dbHelper.getCountingSessions();
      debugPrint("📊 Updated sessions count: ${updatedSessions.length}");

      // ✅ Update state
      state = AsyncData(updatedSessions);

      debugPrint("✅ State updated successfully");
    } catch (e, st) {
      debugPrint("❌ Error in deleteSession: $e");
      debugPrint("Stack trace: $st");

      // ✅ Try to recover by reloading from database
      try {
        final dbHelper = ref.read(dbProvider);
        final sessions = await dbHelper.getCountingSessions();
        state = AsyncData(sessions);
        debugPrint("✅ Recovered state from database");
      } catch (recoveryError) {
        debugPrint("❌ Failed to recover state: $recoveryError");
        state = AsyncError(e, st);
      }

      rethrow;
    }
  }

  // New: Add getSessionStream for real-time session updates
  Stream<CountingSession?> getSessionStream(int productId) {
    final dbHelper = ref.read(dbProvider);
    return dbHelper.watchCountingSessionByProductId(productId);
  }

  // New: Add submitToErp to submit sessions to ERP
  Future<Map<String, dynamic>> submitToErp() async {
    final sessions = state.value ?? [];

    if (sessions.isEmpty) {
      return {
        "success": false,
        "message": "There are no products to submit",
        "skippedProducts": <String>[],
      };
    }

    state = const AsyncLoading();

    try {
      final dbHelper = ref.read(dbProvider);

      // ✅ Use the dynamic provider with async watch
      final submitErpService = await ref.read(
        dynamicSubmitErpServiceProvider.future,
      );

      final List<Map<String, dynamic>> erpData = [];
      final List<String> skippedProducts = [];

      for (final session in sessions) {
        final product = await dbHelper.getProductById(session.productId);
        if (product == null ||
            product.barcode == null ||
            product.barcode!.isEmpty) {
          skippedProducts.add(session.productName ?? 'Unknown Product');
          continue;
        }

        erpData.add({
          'productId': session.productId,
          'itemCode': session.productId, // For Django
          'productName': session.productName,
          'countedQuantity': session.countedQuantity,
          'erpQuantity': session.erpQuantity,
          'barcode': product.barcode,
        });
      }

      if (erpData.isEmpty) {
        state = AsyncData(await dbHelper.getCountingSessions());
        return {
          'success': false,
          'message': 'No valid sessions to submit.',
          'skippedProducts': skippedProducts,
        };
      }

      // Call ERP service (will automatically use the correct backend)
      final result = await submitErpService.submitToErp(erpData);

      // Safely cast skippedProducts from API
      final apiSkippedProducts =
          (result['skippedProducts'] as List<dynamic>?)
              ?.map((e) => e.toString())
              .toList() ??
          [];

      // Only delete successfully submitted sessions
      if (result['success'] == true) {
        for (final session in sessions) {
          if (!apiSkippedProducts.contains(session.productName)) {
            await dbHelper.deleteCountingSession(session.id!);
          }
        }
      }

      // Reload sessions from DB
      state = AsyncData(await dbHelper.getCountingSessions());

      return {
        'success': result['success'] ?? false,
        'message': result['message']?.toString() ?? '',
        'skippedProducts': [...skippedProducts, ...apiSkippedProducts],
      };
    } catch (e, st) {
      state = AsyncError(e, st);
      return {
        'success': false,
        'message': 'Error submitting to ERP: $e',
        'skippedProducts': [],
      };
    }
  }

  void reset() {
    state = const AsyncData([]); // hard reset session list
  }
}

final sessionsNotifierProvider =
    AsyncNotifierProvider<SessionsNotifier, List<CountingSession>>(
      SessionsNotifier.new,
    );

// Scan Request Provider
final scanRequestProvider = StateProvider<bool>((ref) => false);
