import 'package:dio/dio.dart';
import '../constants/api_endpoints.dart';
import '../storage/secure_storage.dart';

class ApiClient {
  late final Dio _dio;
  final SecureStorage _storage = SecureStorage();

  // Singleton instance
  static final ApiClient _instance = ApiClient._internal();
  factory ApiClient() => _instance;

  Dio get dio => _dio;

  ApiClient._internal() {
    _dio = Dio(
      BaseOptions(
        baseUrl: ApiEndpoints.baseUrl,
        connectTimeout: const Duration(seconds: 15),
        receiveTimeout: const Duration(seconds: 15),
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
        },
      ),
    );

    // Add interceptors for secure headers and automatic token refresh
    _dio.interceptors.add(
      InterceptorsWrapper(
        onRequest: (options, handler) async {
          // Fetch token and inject into headers if present
          final token = await _storage.getAccessToken();
          if (token != null && !options.headers.containsKey('Authorization')) {
            options.headers['Authorization'] = 'Bearer $token';
          }
          return handler.next(options);
        },
        onError: (DioException error, handler) async {
          // If token expired (401 Unauthorized), try to refresh it
          if (error.response?.statusCode == 401 && error.requestOptions.path != ApiEndpoints.login) {
            final refreshToken = await _storage.getRefreshToken();
            
            if (refreshToken != null) {
              try {
                // Request a new access token
                final refreshResponse = await Dio(BaseOptions(baseUrl: ApiEndpoints.baseUrl)).post(
                  ApiEndpoints.refreshToken,
                  data: {'refresh': refreshToken},
                );

                if (refreshResponse.statusCode == 200) {
                  final newAccessToken = refreshResponse.data['access'];
                  
                  // Save new access token
                  await _storage.saveAccessToken(newAccessToken);

                  // Retry the original request with the new token
                  final options = error.requestOptions;
                  options.headers['Authorization'] = 'Bearer $newAccessToken';
                  
                  final response = await _dio.fetch(options);
                  return handler.resolve(response);
                }
              } catch (e) {
                // If refresh fails (refresh token expired too), logout user
                await _storage.clearAuthData();
              }
            } else {
              await _storage.clearAuthData();
            }
          }
          return handler.next(error);
        },
      ),
    );
  }
}
