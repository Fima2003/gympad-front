part of 'auth_bloc.dart';

abstract class AuthState extends Equatable {
  const AuthState();
  @override
  List<Object?> get props => [];
}

class AuthInitial extends AuthState {}

class AuthLoading extends AuthState {}

class AuthSigningOut extends AuthState {}

class AuthAuthenticated extends AuthState {
  final String userId;
  final String? gymId;
  final String? authToken;
  const AuthAuthenticated({required this.userId, this.gymId, this.authToken});

  @override
  List<Object?> get props => [userId, gymId, authToken];
}

class AuthGuest extends AuthState {
  final String deviceId;
  const AuthGuest({required this.deviceId});
  @override
  List<Object?> get props => [deviceId];
}

class AuthUnauthenticated extends AuthState {}

class AuthError extends AuthState {
  final String message;
  const AuthError(this.message);
  @override
  List<Object?> get props => [message];
}
