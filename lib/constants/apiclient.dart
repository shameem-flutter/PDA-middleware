import 'package:dio/dio.dart';
import 'package:pda/constants/api_endpoints.dart';
import 'package:cookie_jar/cookie_jar.dart';
import 'package:dio_cookie_manager/dio_cookie_manager.dart';

class ApiClient {
  static final CookieJar cookieJar = CookieJar();
  static final Dio dio = _createDio();

  static Dio _createDio() {
    final dioInstance = Dio(
      BaseOptions(
        baseUrl: ApiEndpoints.baseUrl,
        connectTimeout: const Duration(seconds: 120),
        receiveTimeout: const Duration(seconds: 120),
      ),
    );
    dioInstance.interceptors.add(CookieManager(cookieJar));
    return dioInstance;
  }

  static void updateBaseUrl(String newUrl) {
    dio.options.baseUrl = newUrl;
  }

  static Future<void> clearCookiesForUrl(String baseUrl) async {
    try {
      final uri = Uri.parse(baseUrl);

      await cookieJar.delete(uri);

      await cookieJar.delete(
        Uri(
          scheme: uri.scheme == 'https' ? 'http' : 'https',
          host: uri.host,
          path: '/',
        ),
      );

      await cookieJar.delete(
        Uri(scheme: uri.scheme, host: uri.host, path: '/'),
      );

      await cookieJar.deleteAll();
    } catch (_) {
      try {
        await cookieJar.deleteAll();
      } catch (_) {}
    }
  }

  static Future<void> clearAllCookies() async {
    try {
      await cookieJar.deleteAll();
    } catch (_) {}
  }
}
