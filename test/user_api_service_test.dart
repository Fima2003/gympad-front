import 'package:flutter_test/flutter_test.dart';
import 'package:gympad/services/api/i_api_service.dart';
import 'package:mocktail/mocktail.dart';
import 'package:gympad/services/api/user_api_service.dart';
import 'package:gympad/services/api/models/user_models.dart';

class _MockApiService extends Mock implements IApiService {}

void main() {
  late _MockApiService mockApi;
  late UserApiService userApiService;

  setUpAll(() {
    registerFallbackValue(<String, dynamic>{});
  });

  setUp(() {
    mockApi = _MockApiService();
    userApiService = UserApiService(apiService: mockApi);
  });

  group('UserApiService', () {
    test('userPartialRead returns parsed data on success', () async {
      final partial = UserPartialResponse(name: 'John', gymId: 'gym1');
      when(
        () => mockApi.get<void, UserPartialResponse>(
          any(),
          auth: any(named: 'auth'),
          parser: any(named: 'parser'),
          queryParameters: any(named: 'queryParameters'),
        ),
      ).thenAnswer((invocation) async {
        final parser =
            invocation.namedArguments[#parser]
                as UserPartialResponse Function(dynamic)?;
        return ApiResponse.success(data: parser?.call(partial.toJson()));
      });

      final resp = await userApiService.userPartialRead();
      expect(resp.success, true);
      expect(resp.data?.name, 'John');
      expect(resp.data?.gymId, 'gym1');
    });

    test('userPartialRead returns error on failure', () async {
      when(
        () => mockApi.get<void, UserPartialResponse>(
          any(),
          auth: any(named: 'auth'),
          parser: any(named: 'parser'),
          queryParameters: any(named: 'queryParameters'),
        ),
      ).thenAnswer(
        (_) async => ApiResponse.failure(
          status: 401,
          error: 'Unauthorized',
          message: 'Authentication required',
        ),
      );

      final resp = await userApiService.userPartialRead();
      expect(resp.success, false);
    });

    test('userFullRead returns parsed data on success', () async {
      final full = UserFullResponse(
        email: 'a@b.com',
        name: 'Anna',
        gymId: null,
        workouts: null,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
        lastLoggedIn: DateTime.now(),
      );
      when(
        () => mockApi.get<void, UserFullResponse>(
          any(),
          auth: any(named: 'auth'),
          parser: any(named: 'parser'),
          queryParameters: any(named: 'queryParameters'),
        ),
      ).thenAnswer((invocation) async {
        final parser =
            invocation.namedArguments[#parser]
                as UserFullResponse Function(dynamic)?;
        return ApiResponse.success(data: parser?.call(full.toJson()));
      });

      final resp = await userApiService.userFullRead();
      expect(resp.success, true);
      expect(resp.data?.email, 'a@b.com');
      expect(resp.data?.name, 'Anna');
    });

    test('userUpdate validates empty request', () async {
      final resp = await userApiService.userUpdate();
      expect(resp.success, false);
      expect(resp.status, 400);
      expect(resp.error, 'Validation error');
    });

    test('userUpdate delegates to api put when valid', () async {
      when(
        () => mockApi.put<UserUpdateRequest, void>(
          any(),
          body: any(named: 'body'),
          auth: any(named: 'auth'),
          parser: any(named: 'parser'),
        ),
      ).thenAnswer((_) async => ApiResponse.success());

      final resp = await userApiService.userUpdate(name: 'Neo');
      expect(resp.success, true);
      verify(
        () => mockApi.put<UserUpdateRequest, void>(
          any(),
          body: any(named: 'body'),
          auth: true,
          parser: any(named: 'parser'),
        ),
      ).called(1);
    });

    test('userDelete delegates to api delete', () async {
      when(
        () => mockApi.delete<void, void>(
          any(),
          auth: any(named: 'auth'),
          parser: any(named: 'parser'),
        ),
      ).thenAnswer((_) async => ApiResponse.success());

      final resp = await userApiService.userDelete();
      expect(resp.success, true);
      verify(
        () => mockApi.delete<void, void>(
          any(),
          auth: true,
          parser: any(named: 'parser'),
        ),
      ).called(1);
    });
  });
}
