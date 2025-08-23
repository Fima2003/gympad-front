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

  factory ApiResponse.success({required T data}) {
    return ApiResponse(success: true, status: 200, data: data);
  }

  factory ApiResponse.successEmpty() {
    return ApiResponse(success: true, status: 200);
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
abstract class IApiService {
  Future<ApiResponse<K>> get<T, K>(
    String fName, {
    T? body,
    bool auth = true,
    K Function(dynamic)? parser,
    Map<String, dynamic>? queryParameters,
  });
  Future<ApiResponse<K>> post<T, K>(
    String fName, {
    T? body,
    bool auth = true,
    K Function(dynamic)? parser,
  });
  Future<ApiResponse<K>> put<T, K>(
    String fName, {
    T? body,
    bool auth = true,
    K Function(dynamic)? parser,
  });
  Future<ApiResponse<K>> delete<T, K>(
    String fName, {
    T? body,
    bool auth = true,
    K Function(dynamic)? parser,
  });
}
