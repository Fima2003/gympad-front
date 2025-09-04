import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:gympad/services/api/user_api_service.dart';
import 'package:gympad/services/api/i_api_service.dart';
import 'package:gympad/services/api/models/user_models.dart';

class _MockApiService extends Mock implements IApiService {}

void main() {
  late _MockApiService mockApi;
  late UserApiService service;

  setUp(() {
    mockApi = _MockApiService();
    service = UserApiService(apiService: mockApi);
  });

  group("Construction & Injection", () {
    test("Uses injected IApiService instance", () {
      expect(service.exposedApi, same(mockApi));
    });
    test("Default construction returns singleton", () {
      final instance1 = UserApiService();
      final instance2 = UserApiService();
      expect(identical(instance1, instance2), isTrue);
    });
  });

  group("userPartialRead", () {
    test(
      "Success: delegates to GET with endpoint userPartialRead, auth: true, parser: provided",
      () async {
        when(
          () => mockApi.get<void, UserPartialResponse>(
            'userPartialRead',
            auth: true,
            parser: any(named: 'parser'),
          ),
        ).thenAnswer(
          (_) async => ApiResponse.success(
            data: UserPartialResponse(name: 'John Doe', gymId: '123'),
          ),
        );

        final response = await service.userPartialRead();

        expect(response, isA<ApiResponse<UserPartialResponse>>());
        expect(response.data?.name, 'John Doe');
        expect(response.data?.gymId, '123');
        verify(
          () => mockApi.get<void, UserPartialResponse>(
            'userPartialRead',
            auth: true,
            parser: any(named: 'parser'),
          ),
        ).called(1);
      },
    );

    test(
      "Parser: when given JSON map, returns UserPartialResponse correctly",
      () async {
        final jsonMap = {'name': 'John Doe', 'gymId': '123'};
        when(
          () => mockApi.get<void, UserPartialResponse>(
            'userPartialRead',
            auth: true,
            parser: any(named: 'parser'),
          ),
        ).thenAnswer(
          (_) async =>
              ApiResponse.success(data: UserPartialResponse.fromJson(jsonMap)),
        );
        final response = await service.userPartialRead();
        expect(response.data, isA<UserPartialResponse>());
        expect(response.data?.name, jsonMap['name']);
        expect(response.data?.gymId, jsonMap['gymId']);
      },
    );

    test("Failure: propagates ApiResponse.failure unchanged", () async {
      when(
        () => mockApi.get<void, UserPartialResponse>(
          'userPartialRead',
          auth: true,
          parser: any(named: 'parser'),
        ),
      ).thenAnswer(
        (_) async => ApiResponse.failure(
          status: 500,
          error: 'Server error',
          message: 'Internal server error',
        ),
      );
      final response = await service.userPartialRead();
      expect(response, isA<ApiResponse<UserPartialResponse>>());
      expect(response.status, 500);
      expect(response.error, 'Server error');
      expect(response.message, 'Internal server error');
    });

    test("Ensures no body/queryParameters passed", () async {
      when(
        () => mockApi.get<void, UserPartialResponse>(
          'userPartialRead',
          auth: true,
          parser: any(named: 'parser'),
        ),
      ).thenAnswer(
        (_) async => ApiResponse.success(
          data: UserPartialResponse(name: 'John Doe', gymId: '123'),
        ),
      );

      await service.userPartialRead();

      verify(
        () => mockApi.get<void, UserPartialResponse>(
          'userPartialRead',
          auth: true,
          parser: any(named: 'parser'),
        ),
      ).called(1);
    });
  });

  group("userFullRead", () {
    test(
      "Success: delegates to GET with endpoint userFullRead, auth: true, parser: provided",
      () async {
        when(
          () => mockApi.get<void, UserFullResponse>(
            'userFullRead',
            auth: true,
            parser: any(named: 'parser'),
          ),
        ).thenAnswer(
          (_) async => ApiResponse.success(
            data: UserFullResponse(
              name: 'John Doe',
              gymId: '123',
              email: 'john.doe@example.com',
              createdAt: DateTime.now(),
              updatedAt: DateTime.now(),
              lastLoggedIn: DateTime.now(),
            ),
          ),
        );

        final response = await service.userFullRead();

        expect(response, isA<ApiResponse<UserFullResponse>>());
        expect(response.data?.name, 'John Doe');
        expect(response.data?.gymId, '123');
        expect(response.data?.email, 'john.doe@example.com');
        verify(
          () => mockApi.get<void, UserFullResponse>(
            'userFullRead',
            auth: true,
            parser: any(named: 'parser'),
          ),
        ).called(1);
      },
    );

    test(
      "Parser: when given JSON map, returns UserFullResponse correctly",
      () async {
        final jsonMap = {
          'name': 'John Doe',
          'gymId': '123',
          'email': 'john.doe@example.com',
          'createdAt': DateTime.now().toString(),
          'updatedAt': DateTime.now().toString(),
          'lastLoggedIn': DateTime.now().toString(),
        };
        when(
          () => mockApi.get<void, UserFullResponse>(
            'userFullRead',
            auth: true,
            parser: any(named: 'parser'),
          ),
        ).thenAnswer(
          (_) async =>
              ApiResponse.success(data: UserFullResponse.fromJson(jsonMap)),
        );
        final response = await service.userFullRead();
        expect(response.data, isA<UserFullResponse>());
        expect(response.data?.name, jsonMap['name']);
        expect(response.data?.gymId, jsonMap['gymId']);
        expect(response.data?.email, jsonMap['email']);
        expect(
          response.data?.createdAt,
          DateTime.tryParse(jsonMap['createdAt']!),
        );
        expect(
          response.data?.updatedAt,
          DateTime.tryParse(jsonMap['updatedAt']!),
        );
        expect(
          response.data?.lastLoggedIn,
          DateTime.tryParse(jsonMap['lastLoggedIn']!),
        );
      },
    );

    test("Failure: propagates ApiResponse.failure unchanged", () async {
      when(
        () => mockApi.get<void, UserFullResponse>(
          'userFullRead',
          auth: true,
          parser: any(named: 'parser'),
        ),
      ).thenAnswer(
        (_) async => ApiResponse.failure(
          status: 500,
          error: 'Server error',
          message: 'Internal server error',
        ),
      );
      final response = await service.userFullRead();
      expect(response, isA<ApiResponse<UserFullResponse>>());
      expect(response.status, 500);
      expect(response.error, 'Server error');
      expect(response.message, 'Internal server error');
    });

    test("Ensures no body/queryParameters passed", () async {
      when(
        () => mockApi.get<void, UserFullResponse>(
          'userFullRead',
          auth: true,
          parser: any(named: 'parser'),
        ),
      ).thenAnswer(
        (_) async => ApiResponse.success(
          data: UserFullResponse(
            name: 'John Doe',
            gymId: '123',
            email: 'john.doe@example.com',
            createdAt: DateTime.now(),
            updatedAt: DateTime.now(),
            lastLoggedIn: DateTime.now(),
          ),
        ),
      );

      await service.userFullRead();

      verify(
        () => mockApi.get<void, UserFullResponse>(
          'userFullRead',
          auth: true,
          parser: any(named: 'parser'),
        ),
      ).called(1);
    });
  });

  group("userUpdate", () {
    test(
      "Validation failure when no params provided returns 400 and does not call API",
      () async {
        final resp = await service.userUpdate();
        expect(resp.success, false);
        expect(resp.status, 400);
        verifyNever(
          () => mockApi.put<UserUpdateRequest, void>(
            any(),
            auth: any(named: 'auth'),
            body: any(named: 'body'),
            parser: any(named: 'parser'),
          ),
        );
      },
    );
    test(
      "Success: returns ApiResponse.success with updated user data",
      () async {
        when(
          () => mockApi.put<UserUpdateRequest, void>(
            'userUpdate',
            auth: true,
            body: any(named: 'body'),
            parser: any(named: 'parser'),
          ),
        ).thenAnswer((_) async => ApiResponse.successEmpty());

        final response = await service.userUpdate(
          name: 'John Doe',
          gymId: '123',
        );

        expect(response, isA<ApiResponse<void>>());
        expect(response.status, 200);
        verify(
          () => mockApi.put<UserUpdateRequest, void>(
            'userUpdate',
            auth: true,
            body: any(named: 'body'),
            parser: any(named: 'parser'),
          ),
        ).called(1);
      },
    );

    test("Failure: propagates ApiResponse.failure unchanged", () async {
      when(
        () => mockApi.put<UserUpdateRequest, void>(
          'userUpdate',
          auth: true,
          body: any(named: 'body'),
          parser: any(named: 'parser'),
        ),
      ).thenAnswer(
        (_) async => ApiResponse.failure(
          status: 404,
          error: 'NOT_FOUND',
          message: 'User Not Found',
        ),
      );
      final response = await service.userUpdate(name: 'John Doe', gymId: '123');
      expect(response, isA<ApiResponse<void>>());
      expect(response.status, 404);
      expect(response.error, 'NOT_FOUND');
      expect(response.message, 'User Not Found');
    });

    test("Sends PUT when only name provided", () async {
      when(
        () => mockApi.put<UserUpdateRequest, void>(
          'userUpdate',
          auth: true,
          body: any(named: 'body'),
          parser: any(named: 'parser'),
        ),
      ).thenAnswer((_) async => ApiResponse.successEmpty());

      final response = await service.userUpdate(name: 'John Doe');
      expect(response, isA<ApiResponse<void>>());
      verify(
        () => mockApi.put<UserUpdateRequest, void>(
          'userUpdate',
          auth: true,
          body: any(named: 'body'),
          parser: any(named: 'parser'),
        ),
      ).called(1);
    });

    test("Sends PUT when only gymId provided", () async {
      when(
        () => mockApi.put<UserUpdateRequest, void>(
          'userUpdate',
          auth: true,
          body: any(named: 'body'),
          parser: any(named: 'parser'),
        ),
      ).thenAnswer((_) async => ApiResponse.successEmpty());

      final response = await service.userUpdate(gymId: '123');
      expect(response, isA<ApiResponse<void>>());
      verify(
        () => mockApi.put<UserUpdateRequest, void>(
          'userUpdate',
          auth: true,
          body: any(named: 'body'),
          parser: any(named: 'parser'),
        ),
      ).called(1);
    });

    test("Does not call API when validation fails", () async {
      when(
        () => mockApi.put<UserUpdateRequest, void>(
          'userUpdate',
          auth: true,
          body: any(named: 'body'),
          parser: any(named: 'parser'),
        ),
      ).thenAnswer((_) async => ApiResponse.successEmpty());

      final response = await service.userUpdate();
      expect(response, isA<ApiResponse<void>>());
      verifyNever(
        () => mockApi.put<UserUpdateRequest, void>(
          'userUpdate',
          auth: true,
          body: any(named: 'body'),
          parser: any(named: 'parser'),
        ),
      );
    });

    test("Passing empty name raises 400 BAD_REQUEST", () async {
      when(
        () => mockApi.put<UserUpdateRequest, void>(
          'userUpdate',
          auth: true,
          body: any(named: 'body'),
          parser: any(named: 'parser'),
        ),
      ).thenAnswer((_) async => ApiResponse.successEmpty());
      final response = await service.updateName('');
      expect(response, isA<ApiResponse<void>>());
      expect(response.status, 400);
      expect(response.error, 'Validation error');
      expect(response.message, 'Name cannot be empty');
    });

    test("Sanity check for long and short names", () async {
      final responseLong = await service.updateName(
        'A very long name that exceeds the maximum allowed length length length length length',
      );
      expect(responseLong, isA<ApiResponse<void>>());
      expect(responseLong.status, 400);
      expect(responseLong.error, 'Validation error');
      expect(responseLong.message, 'Name must be between 2 and 50 characters');

      final responseShort = await service.updateName('A');
      expect(responseShort, isA<ApiResponse<void>>());
      expect(responseShort.status, 400);
      expect(responseShort.error, 'Validation error');
      expect(responseShort.message, 'Name must be between 2 and 50 characters');
    });

    test("Sanity check for weird symbols in Gym", () async {
      final response = await service.updateGymId('1@as&^!');
      expect(response, isA<ApiResponse<void>>());
      expect(response.status, 400);
      expect(response.error, 'Validation error');
      expect(response.message, 'Gym ID contains invalid characters');
    });

    test("Sanity check for weird symbols in Name", () async {
      final response = await service.updateName('1@as&^!');
      expect(response, isA<ApiResponse<void>>());
      expect(response.status, 400);
      expect(response.error, 'Validation error');
      expect(response.message, 'Name contains invalid characters');
    });
  });

  group("Convenience Methods", () {
    test(
      "updateName: calls userUpdate (or directly PUT) with only name.",
      () async {
        when(
          () => mockApi.put<UserUpdateRequest, void>(
            'userUpdate',
            auth: true,
            body: any(named: 'body'),
            parser: any(named: 'parser'),
          ),
        ).thenAnswer((_) async => ApiResponse.successEmpty());

        final response = await service.updateName('John Doe');
        expect(response, isA<ApiResponse<void>>());
        verify(
          () => mockApi.put<UserUpdateRequest, void>(
            'userUpdate',
            auth: true,
            body: any(named: 'body'),
            parser: any(named: 'parser'),
          ),
        ).called(1);
      },
    );

    test("updateGymId: calls with only gymId", () async {
      when(
        () => mockApi.put<UserUpdateRequest, void>(
          'userUpdate',
          auth: true,
          body: any(named: 'body'),
          parser: any(named: 'parser'),
        ),
      ).thenAnswer((_) async => ApiResponse.successEmpty());

      final response = await service.updateGymId('123');
      expect(response, isA<ApiResponse<void>>());
      verify(
        () => mockApi.put<UserUpdateRequest, void>(
          'userUpdate',
          auth: true,
          body: any(named: 'body'),
          parser: any(named: 'parser'),
        ),
      ).called(1);
    });

    test("updateNameAndGym: calls with both", () async {
      when(
        () => mockApi.put<UserUpdateRequest, void>(
          'userUpdate',
          auth: true,
          body: any(named: 'body'),
          parser: any(named: 'parser'),
        ),
      ).thenAnswer((_) async => ApiResponse.successEmpty());

      final response = await service.updateNameAndGym('John Doe', '123');
      expect(response, isA<ApiResponse<void>>());
      verify(
        () => mockApi.put<UserUpdateRequest, void>(
          'userUpdate',
          auth: true,
          body: any(named: 'body'),
          parser: any(named: 'parser'),
        ),
      ).called(1);
    });

    test("clearGym: calls with gymId set to empty string('')", () async {
      when(
        () => mockApi.put<UserUpdateRequest, void>(
          'userUpdate',
          auth: true,
          body: any(named: 'body'),
          parser: any(named: 'parser'),
        ),
      ).thenAnswer((_) async => ApiResponse.successEmpty());

      final response = await service.clearGym();
      expect(response, isA<ApiResponse<void>>());
      expect(response.status, 200);
      verify(
        () => mockApi.put<UserUpdateRequest, void>(
          'userUpdate',
          auth: true,
          body: any(named: 'body'),
          parser: any(named: 'parser'),
        ),
      ).called(1);
    });
  });

  group("userDelete", () {
    test(
      "Delegates to DELETE with endpoint userDelete, auth true, no body, parser null",
      () async {
        when(
          () => mockApi.delete<void, void>('userDelete', auth: true),
        ).thenAnswer((_) async => ApiResponse.successEmpty());

        final response = await service.userDelete();
        expect(response, isA<ApiResponse<void>>());
        verify(
          () => mockApi.delete<void, void>('userDelete', auth: true),
        ).called(1);
      },
    );

    test("Propagates success/failure", () async {
      when(
        () => mockApi.delete<void, void>('userDelete', auth: true),
      ).thenAnswer(
        (_) async => ApiResponse.failure(status: 404, error: 'Not Found'),
      );

      final response = await service.userDelete();
      expect(response, isA<ApiResponse<void>>());
      expect(response.success, isFalse);
      expect(response.status, 404);
      expect(response.error, 'Not Found');
    });
  });
}
