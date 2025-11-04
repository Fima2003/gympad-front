part of 'user_settings_bloc.dart';

abstract class UserSettingsState extends Equatable {
  @override
  List<Object?> get props => [];
}

class UserSettingsInitial extends UserSettingsState {}

class UserSettingsLoaded extends UserSettingsState {
  final String weightUnit;

  UserSettingsLoaded({required this.weightUnit});

  UserSettingsLoaded copyWith({String? weightUnit}) =>
      UserSettingsLoaded(weightUnit: weightUnit ?? this.weightUnit);

  @override
  List<Object?> get props => [weightUnit];
}

class UserSettingsError extends UserSettingsState {
  final String error;

  UserSettingsError({required this.error});

  @override
  List<Object?> get props => [error];

  @override
  String toString() {
    return error;
  }
}
