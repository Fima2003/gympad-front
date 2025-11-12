import 'i_api_service.dart';
import 'api_service.dart';
import 'models/user_models.dart';
import 'models/app_error.dart';
import 'models/api_result.dart';

/// User API service class
class UserApiService {
  static final UserApiService _instance = UserApiService._internal();
  factory UserApiService({IApiService? apiService}) {
    if (apiService != null) {
      _instance._api = apiService;
    }
    return _instance;
  }
  UserApiService._internal();

  IApiService _api = ApiService();

  // Exposed for testing / inspection
  IApiService get exposedApi => _api;

  /// Get partial user information (name and gymId)
  ///
  /// Returns user's name and optional gym ID.
  /// Requires authentication.
  ///
  /// Accepts optional [etag] parameter for If-None-Match header to support
  /// HTTP caching. If the remote data hasn't changed (304 NOT MODIFIED),
  /// the returned ApiResult will contain an error with status 304.
  ///
  /// Returns ApiResult<UserPartialResponse> where:
  /// - isError with status 304 indicates cached data should be used
  /// - isError indicates an error occurred
  /// - isSuccess contains the user data
  Future<ApiResult<UserPartialResponse>> userPartialRead({String? etag}) async {
    return await _api.get<void, UserPartialResponse>(
      'userPartialRead',
      auth: true,
      etag: etag,
      parser:
          (data) => UserPartialResponse.fromJson(data as Map<String, dynamic>),
    );
  }

  /// Update user information
  ///
  /// Updates user's name and/or gymId
  /// At least one parameter must be provided
  /// Returns success message on completion
  /// Requires authentication
  Future<ApiResult<void>> userUpdate({String? name, String? gymId}) async {
    final request = UserUpdateRequest(name: name, gymId: gymId);

    // Validate that at least one parameter is provided
    final validity = request.isValid();
    if (validity != "Success") {
      return ApiResult.error(
        AppError(status: 400, error: 'Validation error', message: validity),
      );
    }

    final response = await _api.put<UserUpdateRequest, void>(
      'userUpdate',
      body: request,
      auth: true,
    );
    return response;
  }

  /// Delete user account
  ///
  /// Permanently deletes the user account
  /// Returns success message on completion
  /// Requires authentication
  Future<ApiResult<void>> userDelete() async {
    return await _api.delete<void, void>('userDelete', auth: true);
  }

  // Convenience methods for easier usage

  /// Update only the user's name
  Future<ApiResult<void>> updateName(String name) async {
    return await userUpdate(name: name);
  }

  /// Update only the user's gym ID
  Future<ApiResult<void>> updateGymId(String gymId) async {
    return await userUpdate(gymId: gymId);
  }

  /// Update both name and gym ID
  Future<ApiResult<void>> updateNameAndGym(String name, String gymId) async {
    return await userUpdate(name: name, gymId: gymId);
  }

  /// Clear the user's gym association
  Future<ApiResult<void>> clearGym() async {
    return await userUpdate(gymId: '');
  }
}
