// lib/src/core/api_client.dart
import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';

class ApiClient {
  /// للطلبات العامة (المجلة، المتجر store/v1، إلخ)
  final Dio base;

  /// لطلبات WooCommerce المحمية (wc/v3) – للطلبات مثلاً
  final Dio wc;

  ApiClient()
      : base = Dio(
    BaseOptions(
      baseUrl: 'https://bma-events.com',
      connectTimeout: const Duration(seconds: 60), // ⬅ زدناها
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
    // 🔐 لو عندك مفاتيح WooCommerce (consumer_key / consumer_secret)
    // فيك تزود هالجزء أو تعدله حسب شغلك السابق:
    wc.interceptors.add(
      InterceptorsWrapper(
        onRequest: (options, handler) {
          // حط مفاتيحك هون لو كنت تستخدم query params:
          // options.queryParameters.addAll({
          //   'consumer_key': 'ck_xxx',
          //   'consumer_secret': 'cs_xxx',
          // });
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

    // نفس الفكرة للـ base client
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
