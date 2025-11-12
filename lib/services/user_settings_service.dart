import 'dart:async';

import 'package:logging/logging.dart';
import 'package:rxdart/rxdart.dart';

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

  // BehaviorSubject replays the last emitted value to new subscribers
  late final BehaviorSubject<UserSettings> _userSettingsController;

  UserSettingsService() {
    _userSettingsController = BehaviorSubject<UserSettings>();
  }

  /// Stream of user settings updates.
  /// Emits the cached settings immediately to new subscribers, then any future updates.
  Stream<UserSettings> get userSettingsStream => _userSettingsController.stream;

  /// Initialize settings by loading from cache and syncing with API.
  /// Emits settings to the stream as they become available.
  Future<void> initializeUserSettings() async {
    try {
      // Load cached settings immediately and emit to stream
      final cachedSettings = await _userSettingsLss.get();
      if (cachedSettings != null) {
        _userSettingsController.add(cachedSettings);
        _logger.info('Emitted cached user settings to stream');
      }

      // Fetch fresh settings from API in the background
      unawaited(_syncSettingsFromApi(cachedSettings?.etag));
    } catch (e) {
      _logger.severe('Error in initializeUserSettings: $e');
    }
  }

  /// Sync settings from API and emit updates to stream.
  Future<void> _syncSettingsFromApi(String? etag) async {
    try {
      print(etag);
      final result = await _userSettingsApiService.getSettings(etag: etag);
      await result.fold(
        onError: (error) async {
          if (error.status == 304) {
            _logger.info(
              'User settings not modified (304), keeping local cache',
            );
          } else {
            _logger.warning('Failed to sync user settings from API: $error');
          }
        },
        onSuccess: (data) async {
          _logger.info('Received new user settings from API, updating stream');
          await _userSettingsLss.save(data);
          _userSettingsController.add(data);
        },
      );
    } catch (e) {
      _logger.severe('Error syncing settings from API: $e');
    }
  }

  Future<void> updateUserSettings(
    UpdateUserSettingsRequest newUSettings,
  ) async {
    try {
      await _userSettingsLss.update(
        copyWithFn:
            (current) => current.copyWith(weightUnit: newUSettings.weightUnit),
      );
      // Emit updated settings to stream
      final updated = await _userSettingsLss.get();
      if (updated != null) {
        _userSettingsController.add(updated);
      }
    } catch (e) {
      _logger.severe("Could not update user settings in Local Storage");
    }
    unawaited(_updateUserSettingsApi(newUSettings));
  }

  Future<void> _updateUserSettingsApi(
    UpdateUserSettingsRequest newUSettings,
  ) async {
    final cachedSettings = await _userSettingsLss.get();
    final etag = cachedSettings?.etag;
    final result = await _userSettingsApiService.updateUserSettings(
      newUSettings,
      etag: etag,
    );
    result.fold(
      onError: (error) {
        _logger.warning('Failed to update user settings on API: $error');
      },
      onSuccess: (data) async {
        _logger.info('User settings successfully updated on API');
        await _userSettingsLss.update(
          copyWithFn: (current) => current.copyWith(etag: data.etag),
        );
      },
    );
  }

  /// Cleanup resources when service is no longer needed.
  void dispose() {
    _userSettingsController.close();
  }
}
