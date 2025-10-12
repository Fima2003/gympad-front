import 'package:equatable/equatable.dart';
import 'package:bloc/bloc.dart';

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

  _userSettingsLoad(
    UserSettingsLoad event,
    Emitter<UserSettingsState> emit,
  ) async {
    try {
      final settings = await _userSettingsService.getUserSettings();
      emit(UserSettingsLoaded(weightUnit: settings.weightUnit));
    } catch (e) {
      emit(UserSettingsError(error: e as String));
    }
  }

  _userSettingsUpdate(
    UserSettingsUpdate event,
    Emitter<UserSettingsState> emit,
  ) {
    if (state is UserSettingsLoaded) {
      emit(
        (state as UserSettingsLoaded).copyWith(weightUnit: event.weightUnit),
      );
    }
  }

  _userSettingsSubmit(
    UserSettingsSubmit event,
    Emitter<UserSettingsState> emit,
  ) async {
    final stateToSubmit = (state as UserSettingsLoaded).copyWith();
    final updateSettings = UpdateUserSettingsRequest(
      weightUnit: stateToSubmit.weightUnit,
    );
    await _userSettingsService.updateUserSettings(updateSettings);
  }
}
