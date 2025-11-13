import 'package:equatable/equatable.dart';
import 'package:bloc/bloc.dart';

import '../../models/withAdapters/user_settings.dart';
import '../../services/api/models/user_settings.dto.dart';
import '../../services/user_settings_service.dart';

part 'user_settings_events.dart';
part 'user_settings_state.dart';

class UserSettingsBloc extends Bloc<UserSettingsEvent, UserSettingsState> {
  final UserSettingsService _userSettingsService = UserSettingsService();

  UserSettingsBloc() : super(UserSettingsInitial()) {
    on<UserSettingsLoad>(_userSettingsLoad);
    on<UserSettingsUpdate>(_userSettingsUpdate);
    on<UserSettingsSubmit>(_userSettingsSubmit);
  }

  /// Load user settings and subscribe to updates.
  /// This initializes the service and starts listening to the stream.
  Future<void> _userSettingsLoad(
    UserSettingsLoad event,
    Emitter<UserSettingsState> emit,
  ) async {
    try {
      // Initialize settings (loads cache + starts API sync)
      await _userSettingsService.initializeUserSettings();

      // Use emit.forEach to properly handle stream emissions
      await emit.forEach<UserSettings>(
        _userSettingsService.userSettingsStream,
        onData: (settings) {
          return UserSettingsLoaded(weightUnit: settings.weightUnit);
        },
        onError: (error, stackTrace) {
          return UserSettingsError(error: error.toString());
        },
      );
    } catch (e) {
      emit(UserSettingsError(error: e.toString()));
    }
  }

  /// Update settings locally (updates state, but doesn't save yet).
  /// The UI will see the change immediately.
  void _userSettingsUpdate(
    UserSettingsUpdate event,
    Emitter<UserSettingsState> emit,
  ) {
    if (state is UserSettingsLoaded) {
      emit(
        (state as UserSettingsLoaded).copyWith(weightUnit: event.weightUnit),
      );
    }
  }

  /// Submit settings to the API and local storage.
  /// The stream will emit the updated value.
  Future<void> _userSettingsSubmit(
    UserSettingsSubmit event,
    Emitter<UserSettingsState> emit,
  ) async {
    final stateToSubmit = (state as UserSettingsLoaded).copyWith();
    final updateSettings = UpdateUserSettingsRequest(
      weightUnit: stateToSubmit.weightUnit,
    );
    await _userSettingsService.updateUserSettings(updateSettings);
  }

  @override
  Future<void> close() {
    _userSettingsService.dispose();
    return super.close();
  }
}
