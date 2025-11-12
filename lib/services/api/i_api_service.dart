import 'models/api_result.dart';

/// Main API service interface for handling HTTP requests
/// All methods return ApiResult<K> which encapsulates Either<AppError, K>
abstract class IApiService {
  Future<ApiResult<K>> get<T, K>(
    String fName, {
    T? body,
    bool auth = true,
    K Function(dynamic)? parser,
    Map<String, dynamic>? queryParameters,
    String? etag,
  });

  Future<ApiResult<K>> post<T, K>(
    String fName, {
    T? body,
    bool auth = true,
    K Function(dynamic)? parser,
    String? etag,
  });

  Future<ApiResult<K>> put<T, K>(
    String fName, {
    T? body,
    bool auth = true,
    K Function(dynamic)? parser,
    String? etag,
  });

  Future<ApiResult<K>> delete<T, K>(
    String fName, {
    T? body,
    bool auth = true,
    K Function(dynamic)? parser,
    String? etag,
  });
}
