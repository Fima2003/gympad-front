import 'package:gympad/services/api/i_api_service.dart';

import 'api_service.dart';
import 'models/user_models.dart';

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
  /// Returns user's name and optional gym ID
  /// Requires authentication
  Future<ApiResponse<UserPartialResponse>> userPartialRead() async {
    return await _api.get<void, UserPartialResponse>(
      'userPartialRead',
      auth: true,
      parser:
          (data) => UserPartialResponse.fromJson(data as Map<String, dynamic>),
    );
  }

  /// Get full user information
  ///
  /// Returns complete user profile including email, name, gymId, workouts,
  /// and timestamp information
  /// Requires authentication
  Future<ApiResponse<UserFullResponse>> userFullRead() async {
    return await _api.get<void, UserFullResponse>(
      'userFullRead',
      auth: true,
      parser: (data) => UserFullResponse.fromJson(data as Map<String, dynamic>),
    );
  }

  /// Update user information
  ///
  /// Updates user's name and/or gymId
  /// At least one parameter must be provided
  /// Returns success message on completion
  /// Requires authentication
  Future<ApiResponse<void>> userUpdate({String? name, String? gymId}) async {
    final request = UserUpdateRequest(name: name, gymId: gymId);

    // Validate that at least one parameter is provided
    final validity = request.isValid();
    if (validity != "Success") {
      return ApiResponse.failure(
        status: 400,
        error: 'Validation error',
        message: validity,
      );
    }

    return await _api.put<UserUpdateRequest, void>(
      'userUpdate',
      body: request,
      auth: true,
    );
  }

  /// Delete user account
  ///
  /// Permanently deletes the user account
  /// Returns success message on completion
  /// Requires authentication
  Future<ApiResponse<void>> userDelete() async {
    return await _api.delete<void, void>('userDelete', auth: true);
  }

  // Convenience methods for easier usage

  /// Update only the user's name
  Future<ApiResponse<void>> updateName(String name) async {
    return await userUpdate(name: name);
  }

  /// Update only the user's gym ID
  Future<ApiResponse<void>> updateGymId(String gymId) async {
    return await userUpdate(gymId: gymId);
  }

  /// Update both name and gym ID
  Future<ApiResponse<void>> updateNameAndGym(String name, String gymId) async {
    return await userUpdate(name: name, gymId: gymId);
  }

  /// Clear the user's gym association
  Future<ApiResponse<void>> clearGym() async {
    return await userUpdate(gymId: '');
  }
}
