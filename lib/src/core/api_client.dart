// lib/src/core/api_client.dart
import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';

class ApiClient {
  /// للطلبات العامة (المجلة، المتجر store/v1، إلخ)
  final Dio base;

  /// لطلبات WooCommerce المحمية (wc/v3)
  final Dio wc;

  ApiClient()
      : base = Dio(
    BaseOptions(
      baseUrl: 'https://bma-events.com',
      connectTimeout: const Duration(seconds: 60),
      receiveTimeout: const Duration(seconds: 60),
      responseType: ResponseType.json,
      followRedirects: true,
      validateStatus: (status) {
        return status != null && status < 500;
      },
    ),
  ),
        wc = Dio(
          BaseOptions(
            baseUrl: 'https://bma-events.com/wp-json/wc/v3',
            connectTimeout: const Duration(seconds: 60),
            receiveTimeout: const Duration(seconds: 60),
            responseType: ResponseType.json,
            followRedirects: true,
            validateStatus: (status) {
              return status != null && status < 500;
            },
          ),
        ) {
    // 🔐 WooCommerce Auth FIX (حل 401)
    wc.interceptors.add(
      InterceptorsWrapper(
        onRequest: (options, handler) {
          options.queryParameters.addAll({
            'consumer_key': 'ck_525eb5090e728073b07a13ddee67426d541b0e21',
            'consumer_secret': 'cs_8d00dcabcfc590cc57a15c7ad381d4639ef08693',
          });

          debugPrint('🌐 [WC REQ] ${options.method} ${options.uri}');
          return handler.next(options);
        },
        onResponse: (response, handler) {
          debugPrint(
              '✅ [WC RES] ${response.statusCode} ${response.requestOptions.uri}');
          return handler.next(response);
        },
        onError: (e, handler) {
          debugPrint(
              '❌ [WC ERR] ${e.requestOptions.method} ${e.requestOptions.uri}\n${e.message}');
          return handler.next(e);
        },
      ),
    );

    // base logging
    base.interceptors.add(
      InterceptorsWrapper(
        onRequest: (options, handler) {
          debugPrint('🌐 [REQ] ${options.method} ${options.uri}');
          return handler.next(options);
        },
        onResponse: (response, handler) {
          debugPrint(
              '✅ [RES] ${response.statusCode} ${response.requestOptions.uri}');
          return handler.next(response);
        },
        onError: (e, handler) {
          debugPrint(
              '❌ [ERR] ${e.requestOptions.method} ${e.requestOptions.uri}\n${e.message}');
          return handler.next(e);
        },
      ),
    );
  }
}