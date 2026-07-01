import 'dart:convert';
import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

import 'shop_repository.dart' show apiClientProvider;

class AuthUser {
  final int id;
  final String username;
  final String email;
  final String displayName;

  const AuthUser({
    required this.id,
    required this.username,
    required this.email,
    required this.displayName,
  });
}

class AuthState {
  final String? token;
  final AuthUser? user;

  const AuthState({this.token, this.user});

  bool get isAuthed => token != null && user != null;
}

class AuthNotifier extends StateNotifier<AuthState> {
  final Dio base;
  final FlutterSecureStorage storage = const FlutterSecureStorage();

  AuthNotifier(this.base) : super(const AuthState()) {
    _load();
  }

  Future<void> _load() async {
    final t = await storage.read(key: 'jwt_token');
    final u = await storage.read(key: 'jwt_user');

    if (t != null && u != null) {
      final j = jsonDecode(u) as Map<String, dynamic>;
      state = AuthState(
        token: t,
        user: AuthUser(
          id: (j['id'] as num).toInt(),
          username: j['username']?.toString() ?? '',
          email: j['email']?.toString() ?? '',
          displayName: j['displayName']?.toString() ?? '',
        ),
      );
    }
  }

  Future<void> register({
    required String name,
    required String email,
    required String password,
  }) async {
    try {
      await base.post(
        '/wp-json/bma/v1/register',
        data: {
          'name': name.trim(),
          'email': email.trim(),
          'password': password,
        },
      );

      await login(username: email.trim(), password: password);
    } on DioException catch (e) {
      throw Exception(_extractMessage(e, fallback: 'تعذر إنشاء الحساب'));
    }
  }

  Future<void> login({
    required String username,
    required String password,
  }) async {
    try {
      final res = await base.post(
        '/wp-json/jwt-auth/v1/token',
        data: {
          'username': username.trim(),
          'password': password,
        },
      );

      final token = res.data['token'] as String;

      final me = await base.get(
        '/wp-json/wp/v2/users/me',
        options: Options(headers: {'Authorization': 'Bearer $token'}),
      );

      final user = AuthUser(
        id: (me.data['id'] as num).toInt(),
        username: me.data['slug']?.toString() ?? username.trim(),
        email: me.data['email']?.toString() ?? username.trim(),
        displayName: me.data['name']?.toString() ?? username.trim(),
      );

      state = AuthState(token: token, user: user);

      await storage.write(key: 'jwt_token', value: token);
      await storage.write(
        key: 'jwt_user',
        value: jsonEncode({
          'id': user.id,
          'username': user.username,
          'email': user.email,
          'displayName': user.displayName,
        }),
      );
    } on DioException catch (e) {
      throw Exception(_extractMessage(e, fallback: 'بيانات الدخول غير صحيحة'));
    }
  }

  Future<void> resetPassword({required String email}) async {
    try {
      await base.post(
        '/wp-json/bma/v1/reset-password',
        data: {'email': email.trim()},
      );
    } on DioException catch (e) {
      throw Exception(_extractMessage(e, fallback: 'تعذر إرسال رابط الاستعادة'));
    }
  }

  Future<void> deleteAccount() async {
    final token = state.token;
    if (token == null) {
      throw Exception('يجب تسجيل الدخول أولاً');
    }

    try {
      await base.delete(
        '/wp-json/bma/v1/delete-account',
        options: Options(headers: {'Authorization': 'Bearer $token'}),
      );

      await logout();
    } on DioException catch (e) {
      throw Exception(_extractMessage(e, fallback: 'تعذر حذف الحساب'));
    }
  }

  Future<void> logout() async {
    state = const AuthState();
    await storage.delete(key: 'jwt_token');
    await storage.delete(key: 'jwt_user');
  }

  String _extractMessage(DioException e, {required String fallback}) {
    final data = e.response?.data;

    if (data is Map && data['message'] != null) {
      return data['message'].toString();
    }

    if (data is Map && data['data'] is Map && data['data']['message'] != null) {
      return data['data']['message'].toString();
    }

    return fallback;
  }
}

final authProvider = StateNotifierProvider<AuthNotifier, AuthState>((ref) {
  final base = ref.read(apiClientProvider).base;
  return AuthNotifier(base);
});