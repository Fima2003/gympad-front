import 'dart:convert';
import 'package:dio/dio.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:gympad/services/logger_service.dart';

/// Generic API response model
class ApiResponse<T> {
  final bool success;
  final T? data;
  final String? message;
  final int? status;
  final String? error;

  ApiResponse({
    required this.success,
    this.data,
    this.message,
    this.status,
    this.error,
  });

  factory ApiResponse.success({T? data, String? message}) {
    return ApiResponse(success: true, data: data, message: message);
  }

  factory ApiResponse.failure({
    required int status,
    required String error,
    String? message,
  }) {
    return ApiResponse(
      success: false,
      status: status,
      error: error,
      message: message,
    );
  }
}

/// Main API service class for handling HTTP requests
class ApiService {
  static final ApiService _instance = ApiService._internal();
  factory ApiService() => _instance;
  ApiService._internal();

  late final Dio _dio;
  final AppLogger _logger = AppLogger();

  // Base domain for Firebase Functions
  static const String _baseDomain = 'ocycwbq2ka-uc.a.run.app';

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

    // Add interceptors for logging
    _dio.interceptors.add(
      LogInterceptor(
        request: true,
        requestHeader: true,
        requestBody: true,
        responseHeader: true,
        responseBody: true,
        error: true,
        logPrint: (object) => _logger.info(object.toString()),
      ),
    );

    // Add error interceptor
    _dio.interceptors.add(
      InterceptorsWrapper(
        onError: (error, handler) {
          _logError('HTTP Error', error);
          handler.next(error);
        },
      ),
    );
  }

  /// Build Firebase Function URL for the given function name
  String _buildFunctionUrl(String functionName) {
    return 'https://$functionName-$_baseDomain/';
  }

  /// GET request
  Future<ApiResponse<K>> get<T, K>(
    String fName, {
    T? body,
    bool auth = true,
    K Function(dynamic)? parser,
  }) async {
    try {
      _logInfo('Making GET request to $fName');

      final options = await _buildRequestOptions(auth);
      final url = _buildFunctionUrl(fName);
      final response = await _dio.get(url, options: options);

      return _handleResponse<K>(response, parser);
    } catch (e) {
      return _handleError<K>(e);
    }
  }

  /// POST request
  Future<ApiResponse<K>> post<T, K>(
    String fName, {
    T? body,
    bool auth = true,
    K Function(dynamic)? parser,
  }) async {
    try {
      _logInfo('Making POST request to $fName');

      final options = await _buildRequestOptions(auth);
      final url = _buildFunctionUrl(fName);
      final response = await _dio.post(
        url,
        data: body != null ? jsonEncode(body) : null,
        options: options,
      );

      return _handleResponse<K>(response, parser);
    } catch (e) {
      return _handleError<K>(e);
    }
  }

  /// PUT request
  Future<ApiResponse<K>> put<T, K>(
    String fName, {
    T? body,
    bool auth = true,
    K Function(dynamic)? parser,
  }) async {
    try {
      _logInfo('Making PUT request to $fName');

      final options = await _buildRequestOptions(auth);
      final url = _buildFunctionUrl(fName);
      final response = await _dio.put(
        url,
        data: body != null ? jsonEncode(body) : null,
        options: options,
      );

      return _handleResponse<K>(response, parser);
    } catch (e) {
      return _handleError<K>(e);
    }
  }

  /// DELETE request
  Future<ApiResponse<K>> delete<T, K>(
    String fName, {
    T? body,
    bool auth = true,
    K Function(dynamic)? parser,
  }) async {
    try {
      _logInfo('Making DELETE request to $fName');

      final options = await _buildRequestOptions(auth);
      final url = _buildFunctionUrl(fName);
      final response = await _dio.delete(
        url,
        data: body != null ? jsonEncode(body) : null,
        options: options,
      );

      return _handleResponse<K>(response, parser);
    } catch (e) {
      return _handleError<K>(e);
    }
  }

  /// Build request options with optional authentication
  Future<Options> _buildRequestOptions(bool includeAuth) async {
    final headers = <String, dynamic>{};

    if (includeAuth) {
      String? token = await _getAuthToken();

      if (token != null) {
        headers['Authorization'] = 'Bearer $token';
        _logInfo('Added authorization header');
      } else {
        _logWarning('Authentication required but no token available');
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
      final prefs = await SharedPreferences.getInstance();
      String? cachedToken = prefs.getString('auth_token');

      if (cachedToken != null) {
        _logInfo('Retrieved auth token from local storage');
        return cachedToken;
      }

      // If no cached token, try to get from Firebase
      final user = FirebaseAuth.instance.currentUser;
      if (user != null) {
        try {
          final token = await user.getIdToken();
          // Cache the token in local storage for future use
          if (token != null) {
            await prefs.setString('auth_token', token);
            _logInfo('Retrieved and cached auth token from Firebase');
            return token;
          }
        } catch (e) {
          _logError('Failed to get auth token from Firebase', e);

          // Try to reload user and get token again
          try {
            await user.reload();
            final reloadedUser = FirebaseAuth.instance.currentUser;
            if (reloadedUser != null) {
              final token = await reloadedUser.getIdToken();
              if (token != null) {
                await prefs.setString('auth_token', token);
                _logInfo('Retrieved and cached auth token after user reload');
                return token;
              }
            }
          } catch (reloadError) {
            _logError('Failed to reload user and get token', reloadError);
          }
        }
      } else {
        _logWarning('No authenticated user found');
      }

      return null;
    } catch (e) {
      _logError('Error retrieving auth token', e);
      return null;
    }
  }

  /// Clear cached auth token (call this when user logs out)
  Future<void> clearAuthToken() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove('auth_token');
      _logInfo('Cleared cached auth token');
    } catch (e) {
      _logError('Error clearing auth token', e);
    }
  }

  /// Handle successful response
  ApiResponse<K> _handleResponse<K>(
    Response response,
    K Function(dynamic)? parser,
  ) {
    _logInfo('Response received with status: ${response.statusCode}');

    if (response.statusCode == 200 || response.statusCode == 201) {
      final responseData = response.data;

      // Check if response indicates success
      if (responseData is Map<String, dynamic>) {
        final success = responseData['success'] as bool? ?? false;

        if (success) {
          final data = responseData['data'];
          final message = responseData['message'] as String?;

          if (data != null && parser != null) {
            try {
              final parsedData = parser(data);
              return ApiResponse.success(data: parsedData, message: message);
            } catch (e) {
              _logError('Failed to parse response data', e);
              return ApiResponse.failure(
                status: 500,
                error: 'Data parsing error',
                message: 'Failed to parse response data',
              );
            }
          } else {
            return ApiResponse.success(message: message);
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
    _logError('Request failed', error);

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

  /// Logging methods
  void _logInfo(String message) {
    _logger.info(message);
  }

  void _logWarning(String message) {
    _logger.warning(message);
  }

  void _logError(String message, dynamic error) {
    _logger.error('$message: $error');
  }
}
