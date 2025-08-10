# Cloud Functions API Service Implementation

This implementation provides a comprehensive API service for the gympad Flutter application as specified in the cloud-functions.xml requirements.

## Created Files

### Core API Service
- `lib/services/api/api_service.dart` - Main API service with generic HTTP methods (GET, POST, PUT, DELETE)
- `lib/services/api/api.dart` - Export file for easy importing
- `lib/services/logger_service.dart` - Centralized logging service

### User API Implementation
- `lib/services/api/user_api_service.dart` - User-specific API methods
- `lib/services/api/models/user_models.dart` - User data models and request/response types

### Documentation & Examples
- `lib/services/api/README.md` - Comprehensive API documentation
- `lib/services/LOGGER_README.md` - Logger service documentation
- `lib/services/api_usage_example.dart` - Usage examples for all API methods
- `test/api_service_test.dart` - Unit tests for the API service

## Features Implemented

### ✅ Generic HTTP Methods
- GET, POST, PUT, DELETE functions with generic typing
- Parameters: `fName` (function name), `body` (optional), `auth` (optional, default true)
- Generic types: T (input), K (output)

### ✅ Response Format
- Success: `{success: true, data: data}` or `{success: true, message: message}`
- Error: `{success: false, status: status_number, error: error_description, message: error_message}`

### ✅ Authentication
- Smart token management with local storage caching
- Automatic fallback to Firebase Auth if cached token unavailable
- Token retry mechanism with user reload
- Bearer token in Authorization header
- `clearAuthToken()` method for logout scenarios

### ✅ Firebase Functions URL Structure
- Dynamic URL construction: `https://{functionName}-{baseDomain}/`
- Configurable base domain for different environments
- Proper subdomain-based routing for Firebase Functions

### ✅ Error Handling
- Network errors, timeouts, connection issues
- HTTP status code handling
- Response parsing errors
- Authentication errors

### ✅ Logging
- Centralized AppLogger service with multiple log levels
- Formatted console output with timestamps and context
- Support for error objects and stack traces
- Component-specific child loggers
- Dynamic log level configuration
- Replaced all print statements with proper logging

### ✅ User API Endpoints
- `userPartialRead` - GET, auth required, returns `{name: string, gymId: string?}`
- `userFullRead` - GET, auth required, returns full user object with timestamps
- `userUpdate` - PUT, auth required, input validation (at least one parameter required)
- `userDelete` - DELETE, auth required, returns success message

### ✅ Best Practices
- Type safety with generic models
- Proper error handling and logging
- Dio package for HTTP requests
- Singleton pattern for service instances
- Input validation
- Comprehensive documentation

## Usage

### 1. Initialize (call once at app startup)
```dart
// Initialize logger first
AppLogger().initialize();

// Then initialize API service
ApiService().initialize();
```

### 2. Use the User API
```dart
final userApi = UserApiService();
final logger = AppLogger();

// Get partial user info
final response = await userApi.userPartialRead();
if (response.success && response.data != null) {
  logger.info('User: ${response.data!.name}');
}

// Update user
await userApi.updateName('New Name');
await userApi.updateGymId('gym123');

// Delete user
await userApi.userDelete();
```

### 3. Handle Responses
```dart
if (response.success) {
  // Use response.data or response.message
} else {
  // Handle error: response.status, response.error, response.message
}
```

## Configuration

Update the base domain in `api_service.dart` to match your Firebase project:
```dart
static const String _baseDomain = 'your-project-id-region.a.run.app';
```

Example: If your project ID is `gympad-123` and region is `us-central1`, use:
```dart
static const String _baseDomain = 'gympad-123-us-central1.a.run.app';
```

The service will automatically construct URLs like:
- `https://userPartialRead-gympad-123-us-central1.a.run.app/`
- `https://userFullRead-gympad-123-us-central1.a.run.app/`
- etc.

## Testing

Run the included tests:
```bash
flutter test test/api_service_test.dart
```

The implementation is ready for integration with your cloud functions backend!
