import 'api_service.dart';
import 'i_api_service.dart';
import 'models/exercise.model.dart';

class ExerciseApiService {
  static final ExerciseApiService _instance =
      ExerciseApiService._internal();
  factory ExerciseApiService({IApiService? apiService}) {
    if (apiService != null) {
      _instance._api = apiService;
    }
    return _instance;
  }
  ExerciseApiService._internal();
  IApiService _api = ApiService();
  
  Future<ApiResponse<List<ExerciseR>>> getExercises() async {
    return await _api.get<void, List<ExerciseR>>(
      'getAllExercises',
      parser: (data) => (data as List).map((e) => ExerciseR.fromJson(e)).toList(),
      auth: false,
    );
  }
}