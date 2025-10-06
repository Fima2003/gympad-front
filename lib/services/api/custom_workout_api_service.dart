import 'api_service.dart';
import 'i_api_service.dart';
import 'models/custom_workout.model.dart';

class CustomWorkoutApiService {
  static final CustomWorkoutApiService _instance =
      CustomWorkoutApiService._internal();
  factory CustomWorkoutApiService({IApiService? apiService}) {
    if (apiService != null) {
      _instance._api = apiService;
    }
    return _instance;
  }
  CustomWorkoutApiService._internal();

  IApiService _api = ApiService();

  Future<ApiResponse<List<CustomWorkoutR>>> getCustomWorkouts(
    [String? userLevel]
  ) async {
    final queryParameters = {
      'field': 'difficulty',
      'value': userLevel ?? "Beginner",
      'limit': 10,
    };
    return await _api.get<void, List<CustomWorkoutR>>(
      'getCustomWorkouts',
      queryParameters: queryParameters,
      parser:
          (json) =>
              json
                  .map<CustomWorkoutR>((e) => CustomWorkoutR.fromJson(e))
                  .toList(),
      auth: false,
    );
  }
}
