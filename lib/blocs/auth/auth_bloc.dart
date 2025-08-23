import 'dart:async';
import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:gympad/services/auth_service.dart';
import 'package:gympad/services/logger_service.dart';

part 'auth_event.dart';
part 'auth_state.dart';

/// AuthBloc bridges UI and AuthService keeping UI logic lean & SRP.
class AuthBloc extends Bloc<AuthEvent, AuthState> {
  final AuthService _authService;
  final AppLogger _logger = AppLogger();

  AuthBloc({AuthService? authService})
    : _authService = authService ?? AuthService(),
      super(AuthInitial()) {
    on<AuthAppStarted>(_onAppStarted);
    on<AuthSignInRequested>(_onSignInRequested);
    on<AuthSignOutRequested>(_onSignOutRequested);
    on<AuthRefreshRequested>(_onRefreshRequested);
  }

  Future<void> _onAppStarted(
    AuthAppStarted event,
    Emitter<AuthState> emit,
  ) async {
    emit(AuthLoading());
    try {
      // Attempt remote fetch if already signed in (Firebase session present)
      if (_authService.isSignedIn) {
        await _authService.fetchUserOnAppStartWithRetry();
      }
      final local = await _authService.getLocalUserData();
      final userId = local['userId'];
      if (userId != null) {
        emit(
          AuthAuthenticated(
            userId: userId,
            gymId: local['gymId'],
            authToken: local['auth_token'],
          ),
        );
      } else {
        emit(AuthUnauthenticated());
      }
    } catch (e, st) {
      _logger.error('AuthAppStarted failed', e, st);
      emit(AuthError('Failed to initialize authentication'));
      emit(AuthUnauthenticated());
    }
  }

  Future<void> _onSignInRequested(
    AuthSignInRequested event,
    Emitter<AuthState> emit,
  ) async {
    emit(AuthLoading());
    try {
      final result = await _authService.signInWithGoogle();
      if (result == null) {
        // User cancelled
        emit(AuthUnauthenticated());
        return;
      }
      if (result['success'] == true) {
        emit(
          AuthAuthenticated(
            userId: result['userId'] as String,
            gymId: result['gymId'] as String?,
            authToken: (await _authService.getLocalUserData())['auth_token'],
          ),
        );
      } else {
        emit(AuthError(result['error']?.toString() ?? 'Sign-in failed'));
        emit(AuthUnauthenticated());
      }
    } catch (e, st) {
      _logger.error('Sign in failed', e, st);
      emit(AuthError('Sign in failed: $e'));
      emit(AuthUnauthenticated());
    }
  }

  Future<void> _onSignOutRequested(
    AuthSignOutRequested event,
    Emitter<AuthState> emit,
  ) async {
    emit(AuthSigningOut());
    try {
      await _authService.signOut();
      emit(AuthUnauthenticated());
    } catch (e, st) {
      _logger.error('Sign out failed', e, st);
      emit(AuthError('Sign out failed: $e'));
      // Remain in previous authenticated state if any
      final local = await _authService.getLocalUserData();
      final userId = local['userId'];
      if (userId != null) {
        emit(
          AuthAuthenticated(
            userId: userId,
            gymId: local['gymId'],
            authToken: local['auth_token'],
          ),
        );
      } else {
        emit(AuthUnauthenticated());
      }
    }
  }

  Future<void> _onRefreshRequested(
    AuthRefreshRequested event,
    Emitter<AuthState> emit,
  ) async {
    // Keep existing state but try to update gymId/token from storage.
    try {
      final local = await _authService.getLocalUserData();
      final userId = local['userId'];
      if (userId != null) {
        emit(
          AuthAuthenticated(
            userId: userId,
            gymId: local['gymId'],
            authToken: local['auth_token'],
          ),
        );
      }
    } catch (e, st) {
      _logger.error('Auth refresh failed', e, st);
    }
  }
}
