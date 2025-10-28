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
}
