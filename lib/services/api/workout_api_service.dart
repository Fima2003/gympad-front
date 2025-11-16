import '../../models/personal_workout.dart';
import 'api_service.dart';
import 'models/api_result.dart';
import 'models/personal_workout.model.dart';
import 'models/workout_models.dart';

/// Workout API service providing typed wrappers around Cloud Functions
class WorkoutApiService {
  static final WorkoutApiService _instance = WorkoutApiService._internal();
  factory WorkoutApiService() => _instance;
  WorkoutApiService._internal();

  final ApiService _api = ApiService();

  /// GET getAllMyWorkouts
  /// Returns: List of { id, name?, muscleGroups[] }
  Future<ApiResult<List<WorkoutListItem>>> getAllMyWorkouts() async {
    return _api.get<void, List<WorkoutListItem>>(
      'getAllMyWorkouts',
      auth: true,
      parser: (data) {
        final list = (data as List<dynamic>);
        return list
            .map((e) => WorkoutListItem.fromJson(e as Map<String, dynamic>))
            .toList();
      },
    );
  }

  /// GET getPersonalWorkouts
  /// Returns: List of { name ,description?,exercises:[{ exerciseId, name,sets,weight,reps,restTime }] }
  Future<ApiResult<List<PersonalWorkout>>> getPersonalWorkouts(
    String? etag,
  ) async {
    return _api.get<void, List<PersonalWorkout>>(
      'getPersonalWorkouts',
      auth: true,
      etag: etag,
      parser: (data) {
        final list = (data as List<dynamic>);
        return list
            .map(
              (e) => PersonalWorkoutResponse.fromJson(
                e as Map<String, dynamic>,
              ).toDomain(''),
            )
            .toList();
      },
    );
  }

  /// GET getMyWorkout with query param workoutId
  Future<ApiResult<WorkoutDetailResponse>> getMyWorkout({
    required String workoutId,
  }) async {
    return _api.get<void, WorkoutDetailResponse>(
      'getMyWorkout',
      auth: true,
      queryParameters: {'workoutId': workoutId},
      parser:
          (data) =>
              WorkoutDetailResponse.fromJson(data as Map<String, dynamic>),
    );
  }

  /// POST createWorkout
  /// Input is full workout payload, returns success only
  Future<ApiResult<WorkoutCreateResponse>> logNewWorkout(
    WorkoutCreateRequest request,
  ) async {
    return _api.post<WorkoutCreateRequest, WorkoutCreateResponse>(
      'logNewWorkout',
      body: request,
      auth: true,
      parser:
          (data) =>
              WorkoutCreateResponse.fromJson(data as Map<String, dynamic>),
    );
  }

  /// POST createCustomWorkout
  /// Input is custom workout payload, returns Personal Workout id
  Future<ApiResult<String>> createPersonalWorkout(
    CreatePersonalWorkoutRequest request,
  ) async {
    return _api.post<CreatePersonalWorkoutRequest, String>(
      'createPersonalWorkout',
      body: request,
      auth: true,
      parser: (data) => data as String,
    );
  }

  /// DELETE deleteWorkout
  Future<ApiResult<void>> deleteWorkout(WorkoutDeleteRequest request) async {
    return _api.delete<WorkoutDeleteRequest, void>(
      'deleteWorkout',
      body: request,
      auth: true,
    );
  }
}
