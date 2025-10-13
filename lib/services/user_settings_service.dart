import 'dart:async';

import 'package:logging/logging.dart';

import '../models/withAdapters/user_settings.dart';
import 'api/models/user_settings.dto.dart';
import 'api/user_settings_api_service.dart';
import 'hive/user_settings_lss.dart';
import 'logger_service.dart';

class UserSettingsService {
  // add capabilities
  final UserSettingsApiService _userSettingsApiService =
      UserSettingsApiService();
  final UserSettingsLss _userSettingsLss = UserSettingsLss();
  final Logger _logger = AppLogger().createLogger('UserSettingsService');

  Future<UserSettings> getUserSettings() async {
    try {
      final settings = await _userSettingsLss.get();
      if (settings == null) throw "Settings Not Found in Local Storage";
      return settings;
    } catch (e) {
      _logger.severe(e);
    }

    final settings = await _userSettingsApiService.getSettings();
    if (!settings.success) throw settings.error ?? "Unknown Error Occurred";
    await _userSettingsLss.save(settings.data!);
    return settings.data!;
  }

  Future<void> updateUserSettings(
    UpdateUserSettingsRequest newUSettings,
  ) async {
    try {
      await _userSettingsLss.update(
        copyWithFn:
            (current) => current.copyWith(weightUnit: newUSettings.weightUnit),
      );
    } catch (e) {
      _logger.severe("Could not update user settings in Local Storage");
    }
    unawaited(_userSettingsApiService.updateUserSettings(newUSettings));
  }
}
