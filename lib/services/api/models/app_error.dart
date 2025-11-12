import 'package:equatable/equatable.dart';

/// Represents an error response from the API or other service operations.
///
/// This model is used as the Left case in Either<AppError, T> for type-safe
/// error handling throughout the application.
class AppError extends Equatable {
  /// HTTP status code or application-specific error code
  final int status;

  /// Error type/category identifier
  final String error;

  /// Optional detailed error message for logging and debugging
  final String? message;

  /// Optional ETag from response headers (used for 304 NOT MODIFIED)
  final String? etag;

  AppError({
    required this.status,
    required this.error,
    this.message,
    this.etag,
  });

  /// Create a copy of this error with optional field overrides
  AppError copyWith({
    int? status,
    String? error,
    String? message,
    String? etag,
  }) {
    return AppError(
      status: status ?? this.status,
      error: error ?? this.error,
      message: message ?? this.message,
      etag: etag ?? this.etag,
    );
  }

  @override
  String toString() =>
      'AppError(status: $status, error: $error, message: $message, etag: $etag)';

  @override
  List<Object?> get props => [status, error, message, etag];
}
