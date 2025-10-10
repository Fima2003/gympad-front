import 'dart:convert';
import 'package:dio/dio.dart';
import 'package:firebase_auth/firebase_auth.dart' as fb_auth;
import 'package:flutter/foundation.dart';

import '../../models/withAdapters/user.dart';
import '../hive/user_auth_lss.dart';
import '../logger_service.dart';
import 'i_api_service.dart';

class ApiService implements IApiService {
  static final ApiService _instance = ApiService._internal();
  factory ApiService() => _instance;
  ApiService._internal();

  late final Dio _dio;
  final AppLogger _logger = AppLogger();
  final _userAuthStorage = UserAuthLocalStorageService();

  // Base domain for Firebase Functions
  static const String _baseDomain = 'ocycwbq2ka-uc.a.run.app';
  static const String _localDomain =
      'http://127.0.0.1:5001/gympad-e44fc/us-central1/';

  void initialize() {
    // Note: baseUrl will be set dynamically per request
    _dio = Dio(
      BaseOptions(
        connectTimeout: const Duration(seconds: 30),
        receiveTimeout: const Duration(seconds: 30),
        sendTimeout: const Duration(seconds: 30),
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
        },
      ),
    );

    // Add interceptors for logging (minimal)
    // _dio.interceptors.add(
    //   LogInterceptor(
    //     request: false,
    //     requestHeader: false,
    //     requestBody: false,
    //     responseHeader: false,
    //     responseBody: false,
    //     error: true,
    //   ),
    // );

    // Add error interceptor
    _dio.interceptors.add(
      InterceptorsWrapper(
        onError: (error, handler) {
          _logError("Error: ${error.response?.statusCode ?? ""}", error);
          handler.next(error);
        },
      ),
    );
  }

  /// Build Firebase Function URL for the given function name
  String _buildFunctionUrl(String functionName) {
    if (kDebugMode) {
      return '$_localDomain$functionName/';
    }
    return 'https://$functionName-$_baseDomain/';
  }

  /// GET request
  @override
  Future<ApiResponse<K>> get<T, K>(
    String fName, {
    T? body,
    bool auth = true,
    K Function(dynamic)? parser,
    Map<String, dynamic>? queryParameters,
  }) async => _performRequest<T, K>(
    method: 'GET',
    fName: fName,
    body: body,
    auth: auth,
    parser: parser,
    queryParameters: queryParameters,
  );

  /// POST request
  @override
  Future<ApiResponse<K>> post<T, K>(
    String fName, {
    T? body,
    bool auth = true,
    K Function(dynamic)? parser,
  }) async => _performRequest<T, K>(
    method: 'POST',
    fName: fName,
    body: body,
    auth: auth,
    parser: parser,
  );

  /// PUT request
  @override
  Future<ApiResponse<K>> put<T, K>(
    String fName, {
    T? body,
    bool auth = true,
    K Function(dynamic)? parser,
  }) async => _performRequest<T, K>(
    method: 'PUT',
    fName: fName,
    body: body,
    auth: auth,
    parser: parser,
  );

  /// DELETE request
  @override
  Future<ApiResponse<K>> delete<T, K>(
    String fName, {
    T? body,
    bool auth = true,
    K Function(dynamic)? parser,
  }) async => _performRequest<T, K>(
    method: 'DELETE',
    fName: fName,
    body: body,
    auth: auth,
    parser: parser,
  );

  /// Centralized request performer with auth-retry handling (DRY)
  Future<ApiResponse<K>> _performRequest<T, K>({
    required String method,
    required String fName,
    T? body,
    bool auth = true,
    K Function(dynamic)? parser,
    Map<String, dynamic>? queryParameters,
    int retry = 0,
  }) async {
    try {
      _logger.info('Making $method request to $fName');
      final options = await _buildRequestOptions(auth);
      final url = _buildFunctionUrl(fName);

      Response response;
      switch (method) {
        case 'GET':
          response = await _dio.get(
            url,
            options: options,
            queryParameters: queryParameters,
          );
          break;
        case 'POST':
          response = await _dio.post(
            url,
            data: body != null ? jsonEncode(body) : null,
            options: options,
          );
          break;
        case 'PUT':
          response = await _dio.put(
            url,
            data: body != null ? jsonEncode(body) : null,
            options: options,
          );
          break;
        case 'DELETE':
          response = await _dio.delete(
            url,
            data: body != null ? jsonEncode(body) : null,
            options: options,
          );
          break;
        default:
          throw UnsupportedError('Unsupported HTTP method: $method');
      }

      return _handleResponse<K>(response, parser);
    } catch (e) {
      if (e is DioException &&
          e.type == DioExceptionType.badResponse &&
          (e.response?.statusCode == 401 || e.response?.statusCode == 403) &&
          retry < 1) {
        _logWarning(
          'Auth failed ($method $fName). Attempting token refresh and retry.',
        );
        final refreshed = await _forceRefreshAuthToken();
        if (refreshed) {
          return _performRequest<T, K>(
            method: method,
            fName: fName,
            body: body,
            auth: auth,
            parser: parser,
            queryParameters: queryParameters,
            retry: retry + 1,
          );
        }
      }
      return _handleError<K>(e);
    }
  }

  /// Force refresh auth token and cache it
  Future<bool> _forceRefreshAuthToken() async {
    try {
      final user = fb_auth.FirebaseAuth.instance.currentUser;
      if (user == null) {
        _logWarning('No authenticated user for token refresh');
        return false;
      }
      final freshToken = await user.getIdTokenResult(true);
      if (freshToken.token == null) {
        _logWarning('Token refresh returned null token');
        return false;
      }
      await _userAuthStorage.update(
        copyWithFn: (u) => u.copyWith(authToken: freshToken.token!),
      );
      _logger.info('Auth token refreshed and cached');
      return true;
    } catch (e) {
      _logger.error('Failed to refresh auth token', e);
      return false;
    }
  }

  /// Build request options with optional authentication
  Future<Options> _buildRequestOptions(bool includeAuth) async {
    final headers = <String, dynamic>{};

    if (includeAuth) {
      String? token = await _getAuthToken();

      if (token != null) {
        headers['Authorization'] = 'Bearer $token';
      } else {
        _logger.warning('Authentication required but no token available');
        throw Exception('Authentication required but no token available');
      }
    }

    return Options(headers: headers);
  }

  /// Get authentication token from local storage or Firebase
  /// First tries to get from local storage, then from Firebase,
  /// and gives up if both fail
  Future<String?> _getAuthToken() async {
    try {
      // First try to get token from local storage
      final hive = await _userAuthStorage.get();
      String? cachedToken = hive?.authToken;

      if (cachedToken != null) {
        return cachedToken;
      }

      // If no cached token, try to get from Firebase
      final user = fb_auth.FirebaseAuth.instance.currentUser;
      if (user != null) {
        try {
          final token = await user.getIdToken();
          final localUser =
              await _userAuthStorage.get() ??
              User(userId: user.uid, authToken: token, isGuest: false);
          await _userAuthStorage.save(localUser);
          // Cache the token in local storage for future use
          if (token != null) {
            await _userAuthStorage.update(copyWithFn: (u) => localUser);
            _logger.info('Retrieved and cached auth token from Firebase');
            return token;
          }
        } catch (e) {
          _logger.error('Failed to get auth token from Firebase', e);

          // Try to reload user and get token again
          try {
            await user.reload();
            final reloadedUser = fb_auth.FirebaseAuth.instance.currentUser;
            if (reloadedUser != null) {
              final token = await reloadedUser.getIdToken();
              if (token != null) {
                await _userAuthStorage.update(
                  copyWithFn: (u) => u.copyWith(authToken: token),
                );
                _logger.info(
                  'Retrieved and cached auth token after user reload',
                );
                return token;
              }
            }
          } catch (reloadError) {
            _logger.error('Failed to reload user and get token', reloadError);
          }
        }
      } else {
        _logger.warning('No authenticated user found');
      }

      return null;
    } catch (e) {
      _logger.error('Error retrieving auth token', e);
      return null;
    }
  }

  /// Clear cached auth token (call this when user logs out)
  Future<void> clearAuthToken() async {
    try {
      await _userAuthStorage.clear();
      _logger.info('Cleared cached auth token');
    } catch (e) {
      _logger.error('Error clearing auth token', e);
    }
  }

  /// Handle successful response
  ApiResponse<K> _handleResponse<K>(
    Response response,
    K Function(dynamic)? parser,
  ) {
    _logger.info('Response received with status: ${response.statusCode}');

    if (response.statusCode == 200 || response.statusCode == 201) {
      final responseData = response.data;

      // Check if response indicates success
      if (responseData is Map<String, dynamic>) {
        final success = responseData['success'] as bool? ?? false;

        if (success) {
          final data = responseData['data'];

          if (data != null && parser != null) {
            try {
              final parsedData = parser(data);
              return ApiResponse.success(data: parsedData);
            } catch (e) {
              _logError('Failed to parse response data', e);
              return ApiResponse.failure(
                status: 500,
                error: 'Data parsing error',
                message: 'Failed to parse response data',
              );
            }
          } else {
            return ApiResponse.success(data: data);
          }
        } else {
          // Server returned success: false
          final status =
              responseData['status'] as int? ?? response.statusCode ?? 500;
          final error = responseData['error'] as String? ?? 'Unknown error';
          final message = responseData['message'] as String?;

          return ApiResponse.failure(
            status: status,
            error: error,
            message: message,
          );
        }
      }
    }

    return ApiResponse.failure(
      status: response.statusCode ?? 500,
      error: 'Unexpected response format',
      message: 'The server response was not in the expected format',
    );
  }

  /// Handle errors
  ApiResponse<K> _handleError<K>(dynamic error) {
    if (error is DioException) {
      switch (error.type) {
        case DioExceptionType.connectionTimeout:
        case DioExceptionType.sendTimeout:
        case DioExceptionType.receiveTimeout:
          return ApiResponse.failure(
            status: 408,
            error: 'Request timeout',
            message: 'The request took too long to complete',
          );
        case DioExceptionType.badResponse:
          final statusCode = error.response?.statusCode ?? 500;
          final responseData = error.response?.data;

          if (responseData is Map<String, dynamic>) {
            return ApiResponse.failure(
              status: statusCode,
              error: responseData['error'] as String? ?? 'Server error',
              message: responseData['message'] as String?,
            );
          }

          return ApiResponse.failure(
            status: statusCode,
            error: 'Server error',
            message: 'The server returned an error',
          );
        case DioExceptionType.cancel:
          return ApiResponse.failure(
            status: 499,
            error: 'Request cancelled',
            message: 'The request was cancelled',
          );
        case DioExceptionType.connectionError:
          return ApiResponse.failure(
            status: 503,
            error: 'Connection error',
            message: 'Unable to connect to the server',
          );
        case DioExceptionType.unknown:
        default:
          return ApiResponse.failure(
            status: 500,
            error: 'Unknown error',
            message: error.message ?? 'An unexpected error occurred',
          );
      }
    }

    return ApiResponse.failure(
      status: 500,
      error: 'Unexpected error',
      message: error.toString(),
    );
  }

  void _logWarning(String message) {
    _logger.warning(message);
  }

  void _logError(String message, dynamic error) {
    _logger.error('$message');
  }
}
