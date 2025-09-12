part of 'auth_bloc.dart';

abstract class AuthEvent extends Equatable {
  const AuthEvent();
  @override
  List<Object?> get props => [];
}

class AuthAppStarted extends AuthEvent {}

class AuthSignInRequested extends AuthEvent {}

class AuthSignOutRequested extends AuthEvent {}

class AuthRefreshRequested extends AuthEvent {}

class AuthGuestRequested extends AuthEvent {}
