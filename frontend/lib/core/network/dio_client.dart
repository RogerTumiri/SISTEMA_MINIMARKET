import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import '../../core/constants/api_constants.dart';

const _storage = FlutterSecureStorage();

final dioProvider = Provider<Dio>((ref) {
  final dio = Dio(BaseOptions(
    baseUrl:        ApiConstants.baseUrl,
    connectTimeout: const Duration(seconds: 10),
    receiveTimeout: const Duration(seconds: 30),
    headers: {'Content-Type': 'application/json', 'Accept': 'application/json'},
  ));

  dio.interceptors.add(InterceptorsWrapper(
    onRequest: (options, handler) async {
      final token = await _storage.read(key: 'access_token');
      if (token != null) options.headers['Authorization'] = 'Bearer $token';
      handler.next(options);
    },
    onError: (error, handler) async {
      if (error.response?.statusCode == 401) {
        // Intentar refresh
        try {
          final refreshToken = await _storage.read(key: 'refresh_token');
          if (refreshToken != null) {
            final refreshDio = Dio(BaseOptions(baseUrl: ApiConstants.baseUrl));
            final response = await refreshDio.post('/auth/refresh', data: {'refreshToken': refreshToken});
            final newToken = response.data['data']['accessToken'] as String;
            await _storage.write(key: 'access_token', value: newToken);
            error.requestOptions.headers['Authorization'] = 'Bearer $newToken';
            final retryResponse = await dio.fetch(error.requestOptions);
            return handler.resolve(retryResponse);
          }
        } catch (_) {
          await _storage.deleteAll();
        }
      }
      handler.next(error);
    },
  ));

  return dio;
});
