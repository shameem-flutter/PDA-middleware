import 'dart:io';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:pda/database/appdatabase.dart';
import 'package:pda/models/count_session.dart';
import 'package:pda/models/products.dart';
import 'package:pda/services/api_services/authservice.dart';
import 'package:pda/services/api_services/pda_services.dart';
import 'package:pda/services/api_services/submit_erp.dart';
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

final submitErpServiceProvider = Provider<SubmitErpService>((ref) {
  return SubmitErpService(ref.read(sharedPrefsProvider.future));
});

// Auth State
class AuthState {
  final bool isLoading;
  final bool isLoggedIn;
  final String? userName;
  final String? erpUrl;
  final String? dataBase;

  AuthState({
    required this.isLoading,
    required this.isLoggedIn,
    this.userName,
    this.erpUrl,
    this.dataBase,
  });

  AuthState copyWith({
    bool? isLoading,
    bool? isLoggedIn,
    String? userName,
    String? erpUrl,
    String? dataBase,
  }) {
    return AuthState(
      isLoading: isLoading ?? this.isLoading,
      isLoggedIn: isLoggedIn ?? this.isLoggedIn,
      userName: userName ?? userName,
      erpUrl: erpUrl ?? erpUrl,
      dataBase: dataBase ?? dataBase,
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
    final sessionId = prefs.getString("session_id");
    final erpUrl = prefs.getString("erp_url");

    if (sessionId != null && erpUrl != null) {
      final uri = Uri.parse(erpUrl);
      final cookie = Cookie("session_id", sessionId);
      ApiClient.cookieJar.saveFromResponse(uri, [cookie]);
      log("✅ Restored session cookie into CookieJar: $sessionId");
    } else {
      log("⚠️ No session cookie found in SharedPreferences.");
    }
  }

  Future<void> _checkAuthenticationStatus() async {
    final prefs = await ref.read(sharedPrefsProvider.future);
    final sessionId = prefs.getString("session_id");
    final erpUrl = prefs.getString("erp_url");
    final db = prefs.getString("db");
    final userName = prefs.getString("username");

    if (sessionId != null && erpUrl != null) {
      await _restoreSessionCookie();
    }

    state = state.copyWith(
      isLoggedIn: sessionId != null && erpUrl != null && db != null,
      userName: userName,
      erpUrl: erpUrl,
      dataBase: db,
      isLoading: false,
    );
  }

  Future<bool> login({
    required String baseUrl,
    required String db,
    required String username,
    required String password,
  }) async {
    state = state.copyWith(isLoading: true);
    final success = await ref
        .read(authServiceProvider)
        .login(
          baseUrl: baseUrl,
          db: db,
          username: username,
          password: password,
        );

    if (success) {
      final prefs = await ref.read(sharedPrefsProvider.future);
      final sessionId = prefs.getString("session_id");
      if (sessionId != null) {
        await prefs.setString("erp_url", baseUrl);
        await prefs.setString("db", db);
        await prefs.setString("username", username);
        log("Log in successfully with session $sessionId");
        await ref.read(productsNotifierProvider.notifier).syncProducts();
        state = state.copyWith(
          isLoggedIn: true,
          userName: username,
          erpUrl: baseUrl,
          dataBase: db,
          isLoading: false,
        );
        return true;
      } else {
        log("Login succeeded but session ID missing in prefs!");
        state = state.copyWith(isLoading: false);
        return false;
      }
    } else {
      log("Log in failed");
      state = state.copyWith(isLoading: false);
      return false;
    }
  }

  Future<void> logout() async {
    await ref.read(authServiceProvider).logOut();
    final prefs = await ref.read(sharedPrefsProvider.future);
    await prefs.remove("session_id");
    await prefs.remove("erp_url");
    await prefs.remove("db");
    await prefs.remove("username");
    state = state.copyWith(
      isLoggedIn: false,
      userName: null,
      dataBase: null,
      erpUrl: null,
    );
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
    try {
      final response = await pdaServices.getAllPda();

      if (response == null || response.statusCode != 200) {
        final cached = await dbHelper.getProducts();
        if (cached.isNotEmpty) {
          return cached;
        } else {
          throw Exception('Failed to load products');
        }
      }

      List<Product> productsFromApi = [];

      if (response.data is Map<String, dynamic>) {
        final Map<String, dynamic> jsonData = response.data;
        if (jsonData.containsKey('data') && jsonData['data'] is List) {
          final List<dynamic> itemsList = jsonData['data'];
          productsFromApi = itemsList.map((item) {
            return Product.fromApiMap(item as Map<String, dynamic>);
          }).toList();
          ;
          printOrLog("parsed ${productsFromApi.length} products from API");
        } else {
          printOrLog(
            "Response doesn't contain 'data' field or it's not a List",
          );
        }
      } else if (response.data is List) {
        productsFromApi = (response.data as List)
            .map((item) => Product.fromMap(item as Map<String, dynamic>))
            .toList();
      }

      if (productsFromApi.isNotEmpty) {
        await dbHelper.syncProducts(productsFromApi);
      }

      return productsFromApi;
    } catch (e, _) {
      final cached = await dbHelper.getProducts();
      if (cached.isNotEmpty) {
        return cached;
      } else {
        rethrow;
      }
    }
  }

  Future<void> syncProducts() async {
    try {
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
  final query = ref.watch(searchQueryProvider);

  final products = asyncProducts.value ?? [];
  if (query.isEmpty) return products;

  return products.where((p) {
    final name = (p.name).toLowerCase();
    final barcode = (p.barcode ?? '').toString();
    final productId = (p.productId ?? '').toString();

    return name.contains(query) ||
        barcode.contains(query) ||
        productId.contains(query);
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
      final submitErpService = ref.read(submitErpServiceProvider);
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

      // Call ERP service
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
}

final sessionsNotifierProvider =
    AsyncNotifierProvider<SessionsNotifier, List<CountingSession>>(
      SessionsNotifier.new,
    );

// Scan Request Provider
final scanRequestProvider = StateProvider<bool>((ref) => false);

// Parse function
// List<Product> _parseAndMapProductsInBackground(
//   Map<String, dynamic> responseData,
// ) {
//   final pdaModel = PdaServiceModel.fromJson(responseData);
//   return pdaModel.result.map((r) => r.toLocalProduct()).toList();
// }
