import 'api/api.dart';
import 'logger_service.dart';

/// Example usage of the API services
class ApiUsageExample {
  final UserApiService _userApi = UserApiService();
  final AppLogger _logger = AppLogger();

  /// Initialize the API service (call this once when your app starts)
  void initializeApi() {
    ApiService().initialize();
  }

  /// Example: Handle user logout and clear cached token
  Future<void> exampleLogout() async {
    // Clear cached auth token
    await ApiService().clearAuthToken();
    _logger.info('Cached auth token cleared');
  }

  /// Example: Get partial user information
  Future<void> exampleGetUserPartial() async {
    final response = await _userApi.userPartialRead();
    
    if (response.success && response.data != null) {
      final user = response.data!;
      _logger.info('User name: ${user.name}');
      _logger.info('Gym ID: ${user.gymId ?? 'No gym assigned'}');
    } else {
      _logger.error('Error: ${response.error}');
      _logger.error('Message: ${response.message}');
    }
  }

  /// Example: Get full user information
  Future<void> exampleGetUserFull() async {
    final response = await _userApi.userFullRead();
    
    if (response.success && response.data != null) {
      final user = response.data!;
      _logger.info('Email: ${user.email}');
      _logger.info('Name: ${user.name}');
      _logger.info('Gym ID: ${user.gymId ?? 'No gym assigned'}');
      _logger.info('Created: ${user.createdAt}');
      _logger.info('Last login: ${user.lastLoggedIn}');
    } else {
      _logger.error('Error: ${response.error}');
    }
  }

  /// Example: Update user name
  Future<void> exampleUpdateUserName(String newName) async {
    final response = await _userApi.updateName(newName);
    
    if (response.success) {
      _logger.info('Name updated successfully');
      _logger.info('Message: ${response.message}');
    } else {
      _logger.error('Failed to update name: ${response.error}');
    }
  }

  /// Example: Update user gym
  Future<void> exampleUpdateUserGym(String gymId) async {
    final response = await _userApi.updateGymId(gymId);
    
    if (response.success) {
      _logger.info('Gym updated successfully');
    } else {
      _logger.error('Failed to update gym: ${response.error}');
    }
  }

  /// Example: Update both name and gym
  Future<void> exampleUpdateUserNameAndGym(String name, String gymId) async {
    final response = await _userApi.updateNameAndGym(name, gymId);
    
    if (response.success) {
      _logger.info('User information updated successfully');
    } else {
      _logger.error('Failed to update user: ${response.error}');
    }
  }

  /// Example: Delete user account
  Future<void> exampleDeleteUser() async {
    final response = await _userApi.userDelete();
    
    if (response.success) {
      _logger.info('User account deleted successfully');
    } else {
      _logger.error('Failed to delete user: ${response.error}');
    }
  }

  /// Example: Handle different response scenarios
  Future<void> exampleErrorHandling() async {
    final response = await _userApi.userPartialRead();
    
    if (response.success) {
      // Success case
      if (response.data != null) {
        _logger.info('Data received: ${response.data!.name}');
      } else {
        _logger.info('Success message: ${response.message}');
      }
    } else {
      // Error case
      _logger.error('Request failed:');
      _logger.error('Status: ${response.status}');
      _logger.error('Error: ${response.error}');
      _logger.error('Message: ${response.message}');
      
      // Handle specific error codes
      switch (response.status) {
        case 401:
          _logger.warning('User needs to log in again');
          break;
        case 403:
          _logger.warning('User does not have permission');
          break;
        case 404:
          _logger.warning('User not found');
          break;
        case 500:
          _logger.error('Server error occurred');
          break;
        default:
          _logger.error('Unknown error occurred');
      }
    }
  }
}
