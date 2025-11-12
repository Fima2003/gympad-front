import 'package:dart_either/dart_either.dart';
import 'app_error.dart';

/// ApiResult wraps Either<AppError, T> to provide a consistent, convenient interface
/// for handling API responses throughout the application.
///
/// Instead of working directly with Either, use ApiResult which provides:
/// - Type-safe success and error handling
/// - Convenience methods (fold, map, getOrElse, etc.)
/// - Clear isSuccess/isError predicates
/// - Easy error inspection (status, message)
abstract class ApiResult<T> {
  /// Create a successful result with data
  factory ApiResult.success(T data) = _Success<T>;

  /// Create an error result
  factory ApiResult.error(AppError error) = _Error<T>;

  /// Create from an Either
  factory ApiResult.fromEither(Either<AppError, T> either) {
    return either.fold(
      ifLeft: (error) => _Error<T>(error),
      ifRight: (data) => _Success<T>(data),
    );
  }

  /// Pattern match: apply different functions based on success or error
  /// Returns the result of whichever function is called
  R fold<R>({
    required R Function(AppError error) onError,
    required R Function(T data) onSuccess,
  });

  /// Pattern match with async functions
  /// Useful for making additional async calls based on result
  Future<R> foldAsync<R>({
    required Future<R> Function(AppError error) onError,
    required Future<R> Function(T data) onSuccess,
  });

  /// Transform the success value while preserving errors
  ApiResult<R> map<R>(R Function(T data) transform);

  /// Transform the success value with an async function
  Future<ApiResult<R>> mapAsync<R>(Future<R> Function(T data) transform);

  /// Apply a side effect on success (e.g., logging)
  /// Returns the original result for chaining
  ApiResult<T> tapSuccess(void Function(T data) effect);

  /// Apply a side effect on error
  /// Returns the original result for chaining
  ApiResult<T> tapError(void Function(AppError error) effect);

  /// Get the success value or a default
  T getOrElse(T Function(AppError error) defaultValue);

  /// Get the success value or throw the error
  T getOrThrow();

  /// Get the success value or null
  T? getOrNull();

  /// Get the error or null
  AppError? getErrorOrNull();

  /// Check if this is a success result
  bool get isSuccess;

  /// Check if this is an error result
  bool get isError;

  /// Get HTTP status code (convenience accessor)
  int? get status;

  /// Get error message (convenience accessor)
  String? get errorMessage;

  /// Check if error is due to 304 Not Modified
  bool get is304NotModified;
}

/// Success case: contains the data
class _Success<T> implements ApiResult<T> {
  final T data;

  _Success(this.data);

  @override
  R fold<R>({
    required R Function(AppError error) onError,
    required R Function(T data) onSuccess,
  }) {
    return onSuccess(data);
  }

  @override
  Future<R> foldAsync<R>({
    required Future<R> Function(AppError error) onError,
    required Future<R> Function(T data) onSuccess,
  }) {
    return onSuccess(data);
  }

  @override
  ApiResult<R> map<R>(R Function(T data) transform) {
    try {
      return ApiResult.success(transform(data));
    } catch (e) {
      return ApiResult.error(
        AppError(status: 500, error: 'Transform error', message: e.toString()),
      );
    }
  }

  @override
  Future<ApiResult<R>> mapAsync<R>(Future<R> Function(T data) transform) async {
    try {
      final result = await transform(data);
      return ApiResult.success(result);
    } catch (e) {
      return ApiResult.error(
        AppError(
          status: 500,
          error: 'Async transform error',
          message: e.toString(),
        ),
      );
    }
  }

  @override
  ApiResult<T> tapSuccess(void Function(T data) effect) {
    effect(data);
    return this;
  }

  @override
  ApiResult<T> tapError(void Function(AppError error) effect) {
    // No-op on success
    return this;
  }

  @override
  T getOrElse(T Function(AppError error) defaultValue) {
    return data;
  }

  @override
  T getOrThrow() {
    return data;
  }

  @override
  T? getOrNull() {
    return data;
  }

  @override
  AppError? getErrorOrNull() {
    return null;
  }

  @override
  bool get isSuccess => true;

  @override
  bool get isError => false;

  @override
  int? get status => null;

  @override
  String? get errorMessage => null;

  @override
  bool get is304NotModified => false;

  @override
  String toString() => 'ApiResult.success($data)';
}

/// Error case: contains the AppError
class _Error<T> implements ApiResult<T> {
  final AppError error;

  _Error(this.error);

  @override
  R fold<R>({
    required R Function(AppError error) onError,
    required R Function(T data) onSuccess,
  }) {
    return onError(error);
  }

  @override
  Future<R> foldAsync<R>({
    required Future<R> Function(AppError error) onError,
    required Future<R> Function(T data) onSuccess,
  }) {
    return onError(error);
  }

  @override
  ApiResult<R> map<R>(R Function(T data) transform) {
    // Preserve error on map
    return ApiResult.error(error);
  }

  @override
  Future<ApiResult<R>> mapAsync<R>(Future<R> Function(T data) transform) async {
    // Preserve error on mapAsync
    return ApiResult.error(error);
  }

  @override
  ApiResult<T> tapSuccess(void Function(T data) effect) {
    // No-op on error
    return this;
  }

  @override
  ApiResult<T> tapError(void Function(AppError error) effect) {
    effect(error);
    return this;
  }

  @override
  T getOrElse(T Function(AppError error) defaultValue) {
    return defaultValue(error);
  }

  @override
  T getOrThrow() {
    throw ApiException(error);
  }

  @override
  T? getOrNull() {
    return null;
  }

  @override
  AppError? getErrorOrNull() {
    return error;
  }

  @override
  bool get isSuccess => false;

  @override
  bool get isError => true;

  @override
  int? get status => error.status;

  @override
  String? get errorMessage => error.message;

  @override
  bool get is304NotModified => error.status == 304;

  @override
  String toString() => 'ApiResult.error($error)';
}

/// Exception thrown when calling getOrThrow() on an error result
class ApiException implements Exception {
  final AppError error;

  ApiException(this.error);

  @override
  String toString() => 'ApiException: ${error.error} (status: ${error.status})';
}
