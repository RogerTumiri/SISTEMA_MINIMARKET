import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:dio/dio.dart';
import '../../../core/network/dio_client.dart';
import '../../../core/constants/api_constants.dart';
import '../models/auth_state.dart';
import '../models/usuario_model.dart';

const _storage = FlutterSecureStorage();

class AuthNotifier extends Notifier<AuthState> {
  @override
  AuthState build() {
    Future.microtask(_initFromStorage);
    return const AuthState.initial();
  }

  Dio get _dio => ref.read(dioProvider);

  Future<void> _initFromStorage() async {
    final token = await _storage.read(key: 'access_token');
    if (token != null) {
      try {
        final resp = await _dio.get(ApiConstants.me);
        final user = UsuarioModel.fromJson(resp.data['data'] as Map<String, dynamic>);
        state = AuthState.authenticated(user: user, token: token);
      } catch (_) {
        await _storage.deleteAll();
        state = const AuthState.unauthenticated();
      }
    } else {
      state = const AuthState.unauthenticated();
    }
  }

  Future<void> login(String username, String password) async {
    state = const AuthState.loading();
    try {
      final resp = await _dio.post(ApiConstants.login, data: {
        'username': username,
        'password': password,
      });
      final data = resp.data['data'] as Map<String, dynamic>;
      await _storage.write(key: 'access_token',  value: data['accessToken'] as String);
      await _storage.write(key: 'refresh_token', value: data['refreshToken'] as String);
      final user = UsuarioModel.fromJson(data['usuario'] as Map<String, dynamic>);
      state = AuthState.authenticated(user: user, token: data['accessToken'] as String);
    } on DioException catch (e) {
      final msg = e.response?.data?['error']?['message'] as String? ?? 'Error al iniciar sesión';
      state = AuthState.error(msg);
    }
  }

  Future<void> logout() async {
    try { await _dio.post(ApiConstants.logout); } catch (_) {}
    await _storage.deleteAll();
    state = const AuthState.unauthenticated();
  }
}

final authProvider = NotifierProvider<AuthNotifier, AuthState>(AuthNotifier.new);
