import 'i_api_service.dart';
import 'api_service.dart';
import 'models/questionnaire_models.dart';

class QuestionnaireApiService {
  static final QuestionnaireApiService _instance =
      QuestionnaireApiService._internal();
  factory QuestionnaireApiService({IApiService? apiService}) {
    if (apiService != null) {
      _instance._api = apiService;
    }
    return _instance;
  }
  QuestionnaireApiService._internal();

  IApiService _api = ApiService();

  Future<ApiResponse<void>> submit(QuestionnaireSubmitRequest request) async {
    return await _api.post<QuestionnaireSubmitRequest, void>(
      'questionnaireSubmit',
      body: request,
      auth: true,
    );
  }
}
