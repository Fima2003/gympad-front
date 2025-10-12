part of 'user_settings_bloc.dart';

abstract class UserSettingsEvent extends Equatable {
  @override
  List<Object?> get props => [];
}

class UserSettingsLoad extends UserSettingsEvent {}

class UserSettingsUpdate extends UserSettingsEvent {
  final String? weightUnit;
  UserSettingsUpdate({this.weightUnit});

  @override
  List<Object?> get props => [weightUnit];
}

// no implementation in bloc, because does the same thing. but it's better for readability
class UserSettingsCancel extends UserSettingsLoad {}

class UserSettingsSubmit extends UserSettingsEvent {}