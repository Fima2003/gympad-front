import '../../models/withAdapters/user_settings.dart';
import 'api_service.dart';
import 'i_api_service.dart';
import 'models/api_result.dart';
import 'models/user_settings.dto.dart';

class UserSettingsApiService {
  static final UserSettingsApiService _instance =
      UserSettingsApiService._internal();
  factory UserSettingsApiService({IApiService? apiService}) {
    if (apiService != null) {
      _instance._api = apiService;
    }
    return _instance;
  }
  UserSettingsApiService._internal();

  IApiService _api = ApiService();

  Future<ApiResult<UserSettings>> getSettings({String? etag}) async =>
      await _api.get(
        'getUserSettings',
        auth: true,
        parser: (data) => UserSettings.fromJson(data as Map<String, dynamic>),
        etag: etag,
      );

  Future<ApiResult<UpdateUserSettingsResponse>> updateUserSettings(
    UpdateUserSettingsRequest body, {
    String? etag,
  }) async => await _api.put(
    'updateUserSettings',
    auth: true,
    body: body.toJson(),
    etag: etag,
    parser:
        (data) =>
            UpdateUserSettingsResponse.fromJson(data),
  );
}
