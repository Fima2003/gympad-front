import '../../models/withAdapters/exercise.dart';
import 'api_service.dart';
import 'i_api_service.dart';
import 'models/api_result.dart';

class ExerciseApiService {
  static final ExerciseApiService _instance = ExerciseApiService._internal();
  factory ExerciseApiService({IApiService? apiService}) {
    if (apiService != null) {
      _instance._api = apiService;
    }
    return _instance;
  }
  ExerciseApiService._internal();
  IApiService _api = ApiService();

  Future<ApiResult<List<Exercise>>> getExercises(String goal) async {
    return await _api.get<void, List<Exercise>>(
      'getExercisesForGoal',
      queryParameters: {'goal': goal},
      parser: (data) {
        return (data as List).map((e) => Exercise.fromJson(e)).toList();
      },
      auth: false,
    );
  }
}
