import 'package:pda/constants/shared_pref_constants.dart';
import 'package:pda/utilities/print_function.dart';
import 'package:shared_preferences/shared_preferences.dart';

class ApiEndpoints {
  final Future<SharedPreferences> _prefs;

  ApiEndpoints(this._prefs);

  Future<String> get ipAddress async =>
      (await _prefs).getString(keyIpAddress) ?? "";

  Future<String?> get protocol async => (await _prefs).getString(keyUrlAddress);

  Future<String> get actKeybaseUrl async {
    final ip = await ipAddress;
    final proto = await protocol;
    if (ip.isEmpty) {
      printOrLog("Base URL cannot be constructed because IP is not set.");
    }
    return "$proto$ip/api/v2/license/";
  }

  static const String itemsEndpoint = "item/";
  static const String baseUrl = "https://eleit-sp.febnotech.com/";
}
