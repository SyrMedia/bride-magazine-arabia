import 'dart:convert';
import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

import '../../core/api_client.dart';
import 'shop_repository.dart' show apiClientProvider;

class AuthUser {
  final int id;
  final String username;
  final String email;
  final String displayName;
  const AuthUser({required this.id, required this.username, required this.email, required this.displayName});
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
          id: j['id'] as int,
          username: j['username'] as String,
          email: j['email'] as String,
          displayName: j['displayName'] as String,
        ),
      );
    }
  }

  Future<void> login({required String username, required String password}) async {
    final res = await base.post('/wp-json/jwt-auth/v1/token', data: {
      'username': username,
      'password': password,
    });
    final token = res.data['token'] as String;
    // نجيب بيانات المستخدم (ID) عبر endpoint "me"
    final me = await base.get(
      '/wp-json/wp/v2/users/me',
      options: Options(headers: {'Authorization': 'Bearer $token'}),
    );
    final user = AuthUser(
      id: me.data['id'] as int,
      username: me.data['slug']?.toString() ?? username,
      email: me.data['email']?.toString() ?? '',
      displayName: me.data['name']?.toString() ?? username,
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
  }

  Future<void> logout() async {
    state = const AuthState();
    await storage.delete(key: 'jwt_token');
    await storage.delete(key: 'jwt_user');
  }
}

final authProvider = StateNotifierProvider<AuthNotifier, AuthState>((ref) {
  final base = ref.read(apiClientProvider).base;
  return AuthNotifier(base);
});
