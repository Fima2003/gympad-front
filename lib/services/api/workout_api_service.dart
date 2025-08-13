import 'api_service.dart';
import 'models/workout_models.dart';

/// Workout API service providing typed wrappers around Cloud Functions
class WorkoutApiService {
  static final WorkoutApiService _instance = WorkoutApiService._internal();
  factory WorkoutApiService() => _instance;
  WorkoutApiService._internal();

  final ApiService _api = ApiService();

  /// GET getAllMyWorkouts
  /// Returns: List of { id, name?, muscleGroups[] }
  Future<ApiResponse<List<WorkoutListItem>>> getAllMyWorkouts() async {
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

  /// GET getMyWorkout with query param workoutId
  Future<ApiResponse<WorkoutDetailResponse>> getMyWorkout({
    required String workoutId,
  }) async {
    return _api.get<void, WorkoutDetailResponse>(
      'getMyWorkout',
      auth: true,
      queryParameters: {'workoutId': workoutId},
      parser: (data) =>
          WorkoutDetailResponse.fromJson(data as Map<String, dynamic>),
    );
  }

  /// POST createWorkout
  /// Input is full workout payload, returns success only
  Future<ApiResponse<void>> createWorkout(WorkoutCreateRequest request) async {
    return _api.post<WorkoutCreateRequest, void>(
      'createWorkout',
      body: request,
      auth: true,
    );
  }

  /// DELETE deleteWorkout
  Future<ApiResponse<void>> deleteWorkout(WorkoutDeleteRequest request) async {
    return _api.delete<WorkoutDeleteRequest, void>(
      'deleteWorkout',
      body: request,
      auth: true,
    );
  }
}
