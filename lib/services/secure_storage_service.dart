import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:pda/utilities/print_function.dart';

class SecureStorageService {
  static const FlutterSecureStorage _storage = FlutterSecureStorage(
    aOptions: AndroidOptions(encryptedSharedPreferences: true),
    iOptions: IOSOptions(accessibility: KeychainAccessibility.first_unlock),
  );

  static const String keyToken = "token";
  static const String keySessionId = "session_id";
  static const String keyPassword = "password";
  static const String keyRefreshToken = "refresh_token";

  /// Reads a secure value. Performs automatic migration from SharedPreferences if missing.
  Future<String?> read(String key, {SharedPreferences? prefs}) async {
    try {
      String? value = await _storage.read(key: key);
      if (value != null && value.isNotEmpty) {
        return value;
      }

      // Automatic Migration from SharedPreferences if key exists in legacy store
      if (prefs != null && prefs.containsKey(key)) {
        final legacyValue = prefs.getString(key);
        if (legacyValue != null && legacyValue.isNotEmpty) {
          printOrLog("🔐 Migrating sensitive key '$key' to SecureStorage...");
          await _storage.write(key: key, value: legacyValue);
          await prefs.remove(key);
          return legacyValue;
        }
      }
      return null;
    } catch (e) {
      printOrLog("❌ SecureStorage read error for key $key: $e");
      return null;
    }
  }

  /// Writes a secure key-value pair.
  Future<void> write({
    required String key,
    required String value,
    SharedPreferences? prefs,
  }) async {
    try {
      await _storage.write(key: key, value: value);
      // Ensure key is deleted from plain SharedPreferences if it existed there
      if (prefs != null && prefs.containsKey(key)) {
        await prefs.remove(key);
      }
    } catch (e) {
      printOrLog("❌ SecureStorage write error for key $key: $e");
    }
  }

  /// Deletes a secure key.
  Future<void> delete(String key, {SharedPreferences? prefs}) async {
    try {
      await _storage.delete(key: key);
      if (prefs != null && prefs.containsKey(key)) {
        await prefs.remove(key);
      }
    } catch (e) {
      printOrLog("❌ SecureStorage delete error for key $key: $e");
    }
  }

  /// Clears all sensitive secure storage data.
  Future<void> deleteAll({SharedPreferences? prefs}) async {
    try {
      await _storage.deleteAll();
      if (prefs != null) {
        await prefs.remove(keyToken);
        await prefs.remove(keySessionId);
        await prefs.remove(keyPassword);
        await prefs.remove(keyRefreshToken);
      }
    } catch (e) {
      printOrLog("❌ SecureStorage deleteAll error: $e");
    }
  }
}
