import 'package:flutter/material.dart';
import 'package:dio/dio.dart';
import '../core/constants/api_endpoints.dart';
import '../core/network/api_client.dart';
import '../core/storage/secure_storage.dart';
import '../data/models/user_model.dart';

class AuthProvider extends ChangeNotifier {
  final ApiClient _apiClient = ApiClient();
  final SecureStorage _storage = SecureStorage();

  UserModel? _user;
  bool _isLoading = false;
  String? _errorMessage;

  UserModel? get user => _user;
  bool get isAuthenticated => _user != null;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;

  // Check if user is already logged in on startup
  Future<bool> checkAuthStatus() async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final token = await _storage.getAccessToken();
      if (token != null) {
        // Fetch current user details
        final response = await _apiClient.dio.get(ApiEndpoints.profile);
        if (response.statusCode == 200) {
          _user = UserModel.fromJson(response.data);
          await _storage.saveUsername(_user!.displayName);
          _isLoading = false;
          notifyListeners();
          return true;
        }
      }
    } catch (e) {
      // If profile request fails due to invalid/expired token, clear and fail
      await _storage.clearAuthData();
      _user = null;
    }

    _isLoading = false;
    notifyListeners();
    return false;
  }

  // Register a new user
  Future<bool> register({
    required String username,
    required String email,
    required String password,
    required String firstName,
    required String lastName,
  }) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final response = await _apiClient.dio.post(
        ApiEndpoints.register,
        data: {
          'username': username,
          'email': email,
          'password': password,
          'first_name': firstName,
          'last_name': lastName,
        },
      );

      if (response.statusCode == 201) {
        _isLoading = false;
        notifyListeners();
        // Automatically login the user after registration
        return await login(username: username, password: password);
      }
    } on DioException catch (e) {
      _errorMessage = _parseDioError(e);
    } catch (e) {
      _errorMessage = "An unexpected error occurred during signup.";
    }

    _isLoading = false;
    notifyListeners();
    return false;
  }

  // Login user
  Future<bool> login({
    required String username,
    required String password,
  }) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final response = await _apiClient.dio.post(
        ApiEndpoints.login,
        data: {
          'username': username,
          'password': password,
        },
      );

      if (response.statusCode == 200) {
        final accessToken = response.data['access'];
        final refreshToken = response.data['refresh'];

        // Save tokens securely
        await _storage.saveAccessToken(accessToken);
        await _storage.saveRefreshToken(refreshToken);

        // Fetch user profile info
        final profileResponse = await _apiClient.dio.get(
          ApiEndpoints.profile,
          options: Options(headers: {'Authorization': 'Bearer $accessToken'}),
        );

        if (profileResponse.statusCode == 200) {
          _user = UserModel.fromJson(profileResponse.data);
          await _storage.saveUsername(_user!.displayName);
        }

        _isLoading = false;
        notifyListeners();
        return true;
      }
    } on DioException catch (e) {
      _errorMessage = _parseDioError(e);
    } catch (e) {
      _errorMessage = "An unexpected error occurred during login.";
    }

    _isLoading = false;
    notifyListeners();
    return false;
  }

  // Logout user
  Future<void> logout() async {
    _isLoading = true;
    notifyListeners();
    
    // Clear storage keys
    await _storage.clearAuthData();
    _user = null;
    
    _isLoading = false;
    notifyListeners();
  }

  // Update user profile info (name and email)
  Future<bool> updateProfile({
    required String firstName,
    required String lastName,
    required String email,
  }) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      // Backend exposes profile update as PUT (see routers/auth.py). Using the
      // matching method ensures the change is actually persisted server-side.
      final response = await _apiClient.dio.put(
        ApiEndpoints.profile,
        data: {
          'first_name': firstName,
          'last_name': lastName,
          'email': email,
        },
      );
      if (response.statusCode == 200) {
        _user = UserModel.fromJson(response.data);
        await _storage.saveUsername(_user!.displayName);
        _isLoading = false;
        notifyListeners();
        return true;
      }
    } on DioException catch (e) {
      // Report the real failure rather than faking a local "success" that would
      // silently drift out of sync with the server.
      _errorMessage = _parseDioError(e);
    } catch (e) {
      _errorMessage = "Could not update profile. Please try again.";
    }

    _isLoading = false;
    notifyListeners();
    return false;
  }

  // Change user password
  Future<bool> changePassword({required String oldPassword, required String newPassword}) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final response = await _apiClient.dio.post(
        "auth/password/change/",
        data: {
          'old_password': oldPassword,
          'new_password': newPassword,
        },
      );
      if (response.statusCode == 200 || response.statusCode == 204) {
        _isLoading = false;
        notifyListeners();
        return true;
      }
    } on DioException catch (e) {
      // Surface the real server error instead of pretending the change worked.
      // Silently returning true here would let a user believe their password
      // changed when it did not — a serious security flaw.
      _errorMessage = _parseDioError(e);
    } catch (e) {
      _errorMessage = "Could not change password. Please try again.";
    }

    _isLoading = false;
    notifyListeners();
    return false;
  }

  // Request a password reset code (sent to the account's email).
  // Backend always returns a generic success to avoid leaking whether the
  // account exists, so we treat a 200 as "request accepted".
  Future<bool> requestPasswordReset(String identifier) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final response = await _apiClient.dio.post(
        "auth/password/reset/request/",
        data: {'identifier': identifier},
      );
      _isLoading = false;
      notifyListeners();
      return response.statusCode == 200;
    } on DioException catch (e) {
      _errorMessage = _parseDioError(e);
    } catch (e) {
      _errorMessage = "Could not request a reset code. Please try again.";
    }

    _isLoading = false;
    notifyListeners();
    return false;
  }

  // Confirm a password reset using the emailed code and set a new password.
  Future<bool> confirmPasswordReset({
    required String identifier,
    required String code,
    required String newPassword,
  }) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final response = await _apiClient.dio.post(
        "auth/password/reset/confirm/",
        data: {
          'identifier': identifier,
          'code': code,
          'new_password': newPassword,
        },
      );
      _isLoading = false;
      notifyListeners();
      return response.statusCode == 200;
    } on DioException catch (e) {
      _errorMessage = _parseDioError(e);
    } catch (e) {
      _errorMessage = "Could not reset password. Please try again.";
    }

    _isLoading = false;
    notifyListeners();
    return false;
  }

  // Parse error messages from Dio
  String _parseDioError(DioException e) {
    if (e.response != null && e.response!.data != null) {
      final data = e.response!.data;
      if (data is Map) {
        if (data.containsKey('detail')) {
          return data['detail'];
        }
        if (data.containsKey('non_field_errors')) {
          final errs = data['non_field_errors'];
          if (errs is List && errs.isNotEmpty) return errs.first;
        }
        // Extract field validation errors
        final buffer = StringBuffer();
        data.forEach((key, value) {
          if (value is List && value.isNotEmpty) {
            buffer.write("$key: ${value.first}\n");
          } else if (value is String) {
            buffer.write("$key: $value\n");
          }
        });
        if (buffer.isNotEmpty) return buffer.toString().trim();
      }
    }
    
    if (e.type == DioExceptionType.connectionTimeout || e.type == DioExceptionType.receiveTimeout) {
      return "Network timeout. Please check your internet connection.";
    }
    if (e.type == DioExceptionType.connectionError) {
      return "Cannot connect to server. Please ensure the backend is running.";
    }
    
    return "Something went wrong. Please try again.";
  }
}
