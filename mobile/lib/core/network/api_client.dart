import 'package:dio/dio.dart';
import '../constants/api_constants.dart';
import '../storage/secure_storage_service.dart';

class ApiClient {
  late final Dio dio;
  final SecureStorageService _secureStorage;

  ApiClient({SecureStorageService? secureStorage, String? customBaseUrl})
      : _secureStorage = secureStorage ?? SecureStorageService() {
    dio = Dio(
      BaseOptions(
        baseUrl: customBaseUrl ?? ApiConstants.baseUrl,
        connectTimeout: const Duration(seconds: 10),
        receiveTimeout: const Duration(seconds: 10),
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
        },
      ),
    );

    dio.interceptors.add(
      InterceptorsWrapper(
        onRequest: (options, handler) async {
          final token = await _secureStorage.getAccessToken();
          if (token != null && token.isNotEmpty) {
            options.headers['Authorization'] = 'Bearer $token';
          }
          return handler.next(options);
        },
        onError: (DioException error, handler) {
          // Centralized error handling / logging
          return handler.next(error);
        },
      ),
    );
  }

  // Health check test method
  Future<Map<String, dynamic>> checkHealth() async {
    final response = await dio.get(ApiConstants.health);
    return response.data as Map<String, dynamic>;
  }
}
