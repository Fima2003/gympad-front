import 'dart:convert';
import 'package:dio/dio.dart';
import 'package:firebase_auth/firebase_auth.dart' as fb_auth;
import 'package:flutter/foundation.dart';

import '../../models/withAdapters/user.dart';
import '../hive/user_auth_lss.dart';
import '../logger_service.dart';
import 'etag_utils.dart';
import 'i_api_service.dart';
import 'models/app_error.dart';
import 'models/api_result.dart';

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

    _dio.interceptors.add(
      InterceptorsWrapper(
        onError: (error, handler) {
          final req = error.requestOptions;
          final res = error.response;
          if (res?.statusCode != 304) {
            final details =
                StringBuffer()
                  ..writeln('HTTP ERROR')
                  ..writeln('→ ${req.method} ${req.uri}')
                  ..writeln('Type: ${error.type}')
                  ..writeln('Message: ${error.message}')
                  ..writeln('Status: ${res?.statusCode}')
                  ..writeln('Request headers: ${req.headers}')
                  ..writeln('Request data: ${req.data}')
                  ..writeln('Response data: ${res?.data}')
                  ..writeln('StackTrace: ${error.stackTrace}');

            _logError(details.toString(), error);
          }
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
  Future<ApiResult<K>> get<T, K>(
    String fName, {
    T? body,
    bool auth = true,
    K Function(dynamic)? parser,
    Map<String, dynamic>? queryParameters,
    String? etag,
  }) async => _performRequest<T, K>(
    method: 'GET',
    fName: fName,
    body: body,
    auth: auth,
    parser: parser,
    queryParameters: queryParameters,
    etag: etag,
  );

  /// POST request
  @override
  Future<ApiResult<K>> post<T, K>(
    String fName, {
    T? body,
    bool auth = true,
    K Function(dynamic)? parser,
    String? etag,
  }) async => _performRequest<T, K>(
    method: 'POST',
    fName: fName,
    body: body,
    auth: auth,
    parser: parser,
    etag: etag,
  );

  /// PUT request
  @override
  Future<ApiResult<K>> put<T, K>(
    String fName, {
    T? body,
    bool auth = true,
    K Function(dynamic)? parser,
    String? etag,
  }) async => _performRequest<T, K>(
    method: 'PUT',
    fName: fName,
    body: body,
    auth: auth,
    parser: parser,
    etag: etag,
  );

  /// DELETE request
  @override
  Future<ApiResult<K>> delete<T, K>(
    String fName, {
    T? body,
    bool auth = true,
    K Function(dynamic)? parser,
    String? etag,
  }) async => _performRequest<T, K>(
    method: 'DELETE',
    fName: fName,
    body: body,
    auth: auth,
    parser: parser,
    etag: etag,
  );

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

  /// Build request options with optional authentication
  ///
  /// [match] determines whether to use If-None-Match (true) or If-Match (false) for ETag
  ///
  /// If-None-Match is typically used for GET requests to check if the resource has changed.
  /// If-Match is typically used for PUT/DELETE requests to ensure the resource has not changed.
  ///
  /// ETags are validated before use:
  /// - Invalid or weak ETags are rejected for If-Match (modification requests)
  /// - Both weak and strong ETags are accepted for If-None-Match (GET requests)
  Future<Options> _buildRequestOptions(
    bool includeAuth, {
    String? etag,

    /// If true, use If-None-Match; if false, use If-Match
    bool? match,
  }) async {
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

    if (etag != null) {
      if (match == true) {
        // GET request: If-None-Match - accept both weak and strong ETags
        final validatedEtag = ETagUtils.getIfNoneMatchHeader(etag);
        if (validatedEtag != null) {
          headers['If-None-Match'] = validatedEtag;
        } else {
          _logger.warning('Skipping invalid ETag for If-None-Match: $etag');
        }
      } else {
        // PUT/DELETE request: If-Match - only accept strong ETags
        final validatedEtag = ETagUtils.getIfMatchHeader(etag);
        if (validatedEtag != null) {
          headers['If-Match'] = validatedEtag;
        } else {
          if (ETagUtils.isWeak(etag)) {
            _logger.warning(
              'Weak ETag cannot be used for modification (If-Match): $etag. '
              'Only strong ETags are valid for PUT/DELETE operations.',
            );
          } else {
            _logger.warning('Skipping invalid ETag for If-Match: $etag');
          }
        }
      }
    }

    return Options(headers: headers);
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

  /// Centralized request performer with auth-retry handling (DRY)
  Future<ApiResult<K>> _performRequest<T, K>({
    required String method,
    required String fName,
    T? body,
    bool auth = true,
    K Function(dynamic)? parser,
    Map<String, dynamic>? queryParameters,
    String? etag,
    int retry = 0,
  }) async {
    try {
      _logger.info('Making $method request to $fName');
      final options = await _buildRequestOptions(
        auth,
        etag: etag,
        match: method == 'GET',
      );
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

  /// Handle successful response and convert to ApiResult
  ApiResult<K> _handleResponse<K>(
    Response response,
    K Function(dynamic)? parser,
  ) {
    // Extract function name for logging
    String funcName;
    if (kDebugMode) {
      final path = response.realUri.path.split('/');
      funcName = path[path.length - 2];
    } else {
      funcName =
          response.realUri.pathSegments.isNotEmpty
              ? response.realUri.pathSegments[1]
              : 'unknown';
    }

    // Extract and validate ETag from response headers
    final rawEtag = response.headers.value('etag');
    final etag = ETagUtils.normalizeForStorage(rawEtag);

    // Log ETag validation status for debugging
    if (rawEtag != null && etag == null) {
      _logger.warning(
        'Response from $funcName has invalid or weak ETag: $rawEtag. '
        '${ETagUtils.getValidationErrorMessage(rawEtag)}',
      );
    }

    _logger.info(
      'Response from $funcName received with status: ${response.statusCode}',
    );

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
              return ApiResult.success(parsedData, etag: etag);
            } catch (e, st) {
              _logError('Failed to parse response data: $st', e);
              return ApiResult.error(
                AppError(
                  status: 500,
                  error: 'Data parsing error',
                  message: 'Failed to parse response data',
                  etag: etag,
                ),
              );
            }
          } else {
            return ApiResult.success(data as K, etag: etag);
          }
        } else {
          // Server returned success: false
          final status =
              responseData['status'] as int? ?? response.statusCode ?? 500;
          final error = responseData['error'] as String? ?? 'Unknown error';
          final message = responseData['message'] as String?;

          return ApiResult.error(
            AppError(
              status: status,
              error: error,
              message: message,
              etag: etag,
            ),
          );
        }
      }
    }

    return ApiResult.error(
      AppError(
        status: response.statusCode ?? 500,
        error: 'Unexpected response format',
        message: 'The server response was not in the expected format',
        etag: etag,
      ),
    );
  }

  /// Handle errors and convert to ApiResult
  ApiResult<K> _handleError<K>(dynamic error) {
    if (error is DioException) {
      switch (error.type) {
        case DioExceptionType.connectionTimeout:
        case DioExceptionType.sendTimeout:
        case DioExceptionType.receiveTimeout:
          return ApiResult.error(
            AppError(
              status: 408,
              error: 'Request timeout',
              message: 'The request took too long to complete',
            ),
          );
        case DioExceptionType.badResponse:
          final statusCode = error.response?.statusCode ?? 500;
          final responseData = error.response?.data;
          final rawEtag = error.response?.headers.value('etag');
          final etag = ETagUtils.normalizeForStorage(rawEtag);

          if (rawEtag != null && etag == null) {
            _logger.warning(
              'Error response has invalid or weak ETag: $rawEtag. '
              '${ETagUtils.getValidationErrorMessage(rawEtag)}',
            );
          }

          if (responseData is Map<String, dynamic>) {
            return ApiResult.error(
              AppError(
                status: statusCode,
                error: responseData['error'] as String? ?? 'Server error',
                message: responseData['message'] as String?,
                etag: etag,
              ),
            );
          }

          return ApiResult.error(
            AppError(
              status: statusCode,
              error: 'Server error',
              message: 'The server returned an error',
              etag: etag,
            ),
          );
        case DioExceptionType.cancel:
          return ApiResult.error(
            AppError(
              status: 499,
              error: 'Request cancelled',
              message: 'The request was cancelled',
            ),
          );
        case DioExceptionType.connectionError:
          return ApiResult.error(
            AppError(
              status: 503,
              error: 'Connection error',
              message: 'Unable to connect to the server',
            ),
          );
        case DioExceptionType.unknown:
        default:
          return ApiResult.error(
            AppError(
              status: 500,
              error: 'Unknown error',
              message: error.message ?? 'An unexpected error occurred',
            ),
          );
      }
    }

    return ApiResult.error(
      AppError(
        status: 500,
        error: 'Unexpected error',
        message: error.toString(),
      ),
    );
  }

  void _logWarning(String message) {
    _logger.warning(message);
  }

  void _logError(String message, dynamic error) {
    _logger.error(message);
  }
}
