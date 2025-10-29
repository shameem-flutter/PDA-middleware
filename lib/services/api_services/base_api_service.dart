import 'dart:developer';
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:pda/constants/apiclient.dart';
import 'package:pda/utilities/print_function.dart';
import 'package:shared_preferences/shared_preferences.dart';

Duration connectTimeout = const Duration(seconds: 120);

class BaseApiServices {
  final Dio dio;
  final Future<SharedPreferences> _prefs;

  BaseApiServices({Dio? dio, required Future<SharedPreferences> prefs})
    : dio = dio ?? ApiClient.dio,
      _prefs = prefs;

  Future<Response?> get({
    required String endpoint,
    dynamic data,
    Map<String, dynamic>? headers,
    Map<String, dynamic>? queryParameters,
    String? sharedPrefKey,
  }) async {
    try {
      final response = await dio.get(
        endpoint,
        options: Options(headers: headers),
        data: data,
        queryParameters: queryParameters,
      );
      // In BaseApiServices.get() method, add this before the dio.get call:
      final fullUrl = dio.options.baseUrl + endpoint;
      printOrLog("Full URL being called: $fullUrl");
      printOrLog("Headers: $headers");
      printOrLog("Query Parameters: $queryParameters");

      if (sharedPrefKey != null) {
        printOrLog("Saving GET response to sharedPrefKey: $sharedPrefKey");
        (await _prefs).setString(sharedPrefKey, response.data.toString());
      }
      // printOrLog("GET $endpoint Response: ${response.data}");

      return response;
    } on DioException catch (e) {
      printOrLog(
        "GET $endpoint DioException: ${e.response?.statusCode} - ${e.response?.data}",
      );
      return e.response;
    } catch (e) {
      printOrLog("GET $endpoint error: $e");
      return null;
    }
  }

  Future<Response?> post({
    required String endpoint,
    required dynamic data,
    Map<String, dynamic>? headers,
    String? sharedPrefKey,
  }) async {
    try {
      printOrLog("Data: $data");
      final response = await dio.post(
        endpoint,
        data: data,
        options: Options(headers: headers),
      );

      if (sharedPrefKey != null) {
        (await _prefs).setString(sharedPrefKey, response.data.toString());
      }
      printOrLog("POST $endpoint Response: ${response.data}");

      return response;
    } on DioException catch (e) {
      printOrLog(
        "POST $endpoint DioException: ${e.response?.statusCode} - ${e.response?.data}",
      );
      return e.response;
    } catch (e) {
      printOrLog("POST $endpoint error: $e");
      return null;
    }
  }
}

class ApiState<T> {
  T? data;
  bool isLoaded;
  String? error;

  ApiState({this.data, this.isLoaded = false, this.error});
}

Future<T?> callApiWithState<T>({
  required BuildContext context,
  required ApiState<T> state,
  required Future<Response?> Function() apiCall,
  required T Function(dynamic json) parser,
  required VoidCallback setState,
  bool? isInsideHome = true,
}) async {
  state
    ..isLoaded = false
    ..error = null;
  setState();

  try {
    // if (isInsideHome == true) {
    //   final token = getAccessToken();
    //   if (token == null) {
    //     navigateToLogin(context);
    //     state
    //       ..isLoaded = true
    //       ..error = isSessionExpired()
    //           ? sessionExpiredMessage
    //           : "Token not found"
    //       ..data = null;
    //     setState();
    //     return null;
    //   }
    // }

    final response = await apiCall();

    if (response == null ||
        response.statusCode == null ||
        response.statusCode! < 200 ||
        response.statusCode! >= 300) {
      final rawError =
          response?.data is Map && response?.data['message'] != null
          ? response!.data['message'].toString()
          : "Failed: ${response?.statusMessage}";
      final err = capitalizeFirstLetter(rawError);
      log("API Error: $err");
      state
        ..error = err
        ..data = null;
      setState();
      return null;
    }

    final parsedData = parser(response.data);
    state
      ..data = parsedData
      ..error = null;
    return parsedData;
  } on DioException catch (e) {
    final rawDioError =
        e.response?.data is Map && e.response?.data['message'] != null
        ? e.response!.data['message'].toString()
        : "Dio error: ${e.message}";
    final dioError = capitalizeFirstLetter(rawDioError);
    state
      ..error = dioError
      ..data = null;
  } catch (e) {
    state
      ..error = "Unexpected error: $e"
      ..data = null;
  } finally {
    state.isLoaded = true;
    setState();
  }

  return null;
}

// void navigateToLogin(BuildContext context) {
//   Navigator.pushAndRemoveUntil(
//     context,
//     MaterialPageRoute(builder: (context) => LoginScreen()),
//     (route) => false,
//   );
// }

String capitalizeFirstLetter(String message) {
  if (message.isEmpty) return message;
  return message[0].toUpperCase() + message.substring(1);
}
