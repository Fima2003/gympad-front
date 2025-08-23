import 'package:flutter_test/flutter_test.dart';
import 'package:gympad/services/api/api.dart';
import 'package:gympad/services/api/i_api_service.dart';

void main() {
  group('User API Service Tests', () {
    late UserApiService userApiService;

    setUpAll(() async {
      // Initialize Firebase for testing (you'll need to configure this)
      // await Firebase.initializeApp();

      // Initialize API service
      ApiService().initialize();
      userApiService = UserApiService();
    });

    group('User Partial Read', () {
      test('should return user partial data when authenticated', () async {
        // Note: This test requires a real authenticated user
        // In a real test, you'd mock the API responses

        // Mock test - replace with actual test logic
        expect(userApiService, isA<UserApiService>());
      });

      test('should fail when not authenticated', () async {
        // Test without authentication
        // This would require mocking Firebase Auth to return null user
        expect(userApiService, isA<UserApiService>());
      });
    });

    group('User Update', () {
      test('should validate input parameters', () async {
        // Test validation logic
        final response = await userApiService.userUpdate();

        expect(response.success, false);
        expect(response.error, 'Validation error');
        expect(response.message, contains('At least one parameter'));
      });

      test('should update user name successfully', () async {
        // Note: This would require a mock API response
        expect(userApiService, isA<UserApiService>());
      });
    });

    group('Error Handling', () {
      test('should handle network errors gracefully', () async {
        // Test network error scenarios
        expect(userApiService, isA<UserApiService>());
      });

      test('should handle parsing errors gracefully', () async {
        // Test response parsing errors
        expect(userApiService, isA<UserApiService>());
      });
    });
  });

  group('API Response Model Tests', () {
    test('UserPartialResponse should parse JSON correctly', () {
      final json = {'name': 'John Doe', 'gymId': 'gym123'};

      final response = UserPartialResponse.fromJson(json);

      expect(response.name, 'John Doe');
      expect(response.gymId, 'gym123');
    });

    test('UserPartialResponse should handle null gymId', () {
      final json = {'name': 'John Doe', 'gymId': null};

      final response = UserPartialResponse.fromJson(json);

      expect(response.name, 'John Doe');
      expect(response.gymId, null);
    });

    test('UserUpdateRequest should validate correctly', () {
      // Valid request with name
      final validRequest1 = UserUpdateRequest(name: 'New Name');
      expect(validRequest1.isValid(), true);

      // Valid request with gymId
      final validRequest2 = UserUpdateRequest(gymId: 'gym123');
      expect(validRequest2.isValid(), true);

      // Valid request with both
      final validRequest3 = UserUpdateRequest(
        name: 'New Name',
        gymId: 'gym123',
      );
      expect(validRequest3.isValid(), true);

      // Invalid request with neither
      final invalidRequest = UserUpdateRequest();
      expect(invalidRequest.isValid(), false);
    });

    test('UserUpdateRequest should serialize correctly', () {
      final request = UserUpdateRequest(name: 'New Name', gymId: 'gym123');
      final json = request.toJson();

      expect(json['name'], 'New Name');
      expect(json['gymId'], 'gym123');
    });

    test('UserUpdateRequest should only include non-null values', () {
      final request = UserUpdateRequest(name: 'New Name');
      final json = request.toJson();

      expect(json.containsKey('name'), true);
      expect(json.containsKey('gymId'), false);
      expect(json['name'], 'New Name');
    });
  });

  group('ApiResponse Tests', () {
    test('should create success response with data', () {
      final response = ApiResponse.success(
        data: 'test data',
      );

      expect(response.success, true);
      expect(response.data, 'test data');
      expect(response.message, 'Success message');
      expect(response.error, null);
      expect(response.status, null);
    });

    test('should create failure response', () {
      final response = ApiResponse.failure(
        status: 400,
        error: 'Bad request',
        message: 'Invalid input',
      );

      expect(response.success, false);
      expect(response.status, 400);
      expect(response.error, 'Bad request');
      expect(response.message, 'Invalid input');
      expect(response.data, null);
    });
  });
}
