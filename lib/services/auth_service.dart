import 'dart:async';
import 'package:firebase_auth/firebase_auth.dart' as fb_auth;
import 'package:google_sign_in/google_sign_in.dart';
import 'package:flutter/foundation.dart';
import 'package:logging/logging.dart';

import '../models/withAdapters/user.dart';
import 'logger_service.dart';
import 'hive/user_auth_lss.dart';
import './api/user_api_service.dart';
import 'questionnaire_service.dart';
import 'workout_service.dart';

class AuthService {
  static final AuthService _instance = AuthService._internal();
  factory AuthService() => _instance;
  AuthService._internal();

  final fb_auth.FirebaseAuth _auth = fb_auth.FirebaseAuth.instance;
  final UserApiService _userApiService = UserApiService();
  final QuestionnaireService _questionnaireService = QuestionnaireService();
  final WorkoutService _workoutService = WorkoutService();

  final Logger _logger = AppLogger().createLogger('AuthService');

  final _userAuthStorage = UserAuthLocalStorageService();

  // --- Initialization control ---
  bool _initialized = false;
  Completer<void>? _initCompleter;

  /// Indicates whether [initialize] has completed successfully at least once.
  bool get isInitialized => _initialized;

  /// One-time async initializer for the singleton.
  ///
  /// Safe to call multiple times; concurrent callers will await the same future.
  /// Typical call site: early in app bootstrap (e.g. before runApp in main or
  /// inside a top-level InitBloc / Splash sequence).
  ///
  /// What it currently does (can be extended):
  /// 1. Warm Hive-backed auth + questionnaire local caches.
  /// 2. Optionally attempt a lightweight backend user fetch (token refresh).
  /// 3. Kick questionnaire pending upload retry (non-blocking semantics here).
  ///
  /// Returns normally even if non-critical steps fail; fatal errors are logged.
  Future<void> initialize() async {
    // Ensure no double-call
    if (_initialized) return;
    if (_initCompleter != null) {
      return _initCompleter!.future;
    }
    _initCompleter = Completer<void>();

    _logger.config('initialize() start');
    try {
      _initialized = true;
      _logger.info('initialize() complete');
    } catch (e, st) {
      _logger.severe('initialization failed', e, st);
    } finally {
      _initCompleter!.complete();
    }
  }

  /// Check locally saved user data (userId and gymId exist)
  Future<Map<String, String?>> getLocalUserData() async {
    final hiveUser = await _userAuthStorage.get();
    final hiveQuestionnaire = await _questionnaireService.load();
    _logger.config('Retrieved userId from Hive: ${hiveUser?.userId}');
    return {
      'userId': hiveUser?.userId,
      'gymId': hiveUser?.gymId,
      'authToken': hiveUser?.authToken,
      'isGuest': hiveUser?.isGuest == true ? 'true' : null,
      'completedQuestionnaire': hiveQuestionnaire?.completed.toString(),
    };
  }

  /// Save user data locally
  Future<void> saveLocalUserData({
    String? userId,
    String? gymId,
    String? idToken,
    bool? isGuest,
    bool? completedQuestionnaire,
    UserLevel? level,
  }) async {
    await _userAuthStorage.update(
      copyWithFn:
          (User u) => u.copyWith(
            userId: userId,
            gymId: gymId,
            authToken: idToken,
            level: level,
            isGuest: isGuest,
          ),
    );
    if (completedQuestionnaire != null) {
      await _questionnaireService.markCompleted(completedQuestionnaire);
    }
  }

  Future<void> markGuestSelected(String deviceId) async {
    // DeviceId not stored here (kept by DeviceIdentityService), just set guest flag.
    await _userAuthStorage.update(
      copyWithFn: (User u) => u.copyWith(isGuest: true),
    );
  }

  /// Clear local user data
  Future<void> clearLocalUserData() async {
    await _userAuthStorage.clear();
    await _questionnaireService.clear();
    await _workoutService.clearAll();
  }

  /// Sign in with Google and register/login with backend
  Future<Map<String, dynamic>?> signInWithGoogle() async {
    try {
      // Sign in via Google
      fb_auth.UserCredential userCredential;
      if (kIsWeb) {
        // Web: use Firebase Auth popup
        final provider = fb_auth.GoogleAuthProvider();
        provider.addScope('email');
        provider.addScope('profile');
        userCredential = await _auth.signInWithPopup(provider);
      } else {
        await GoogleSignIn.instance.initialize();
        // Mobile: sign in with google_sign_in plugin
        final googleUser = await GoogleSignIn.instance.authenticate();
        final googleAuth = googleUser.authentication;
        // Create credential with ID token
        final credential = fb_auth.GoogleAuthProvider.credential(
          idToken: googleAuth.idToken,
        );
        userCredential = await _auth.signInWithCredential(credential);
      }
      final user = userCredential.user;
      if (user == null) throw Exception('Google sign-in failed');

      final idToken = await user.getIdToken();
      if (idToken == null) throw Exception('Could not verify token');

      // Register/login with backend
      await user.reload();
      final backendResponse = await _userApiService.userPartialRead();
      if (backendResponse.success) {
        _logger.info('User registered with backend: ${user.uid}');
        await saveLocalUserData(
          userId: user.uid,
          gymId: backendResponse.data?.gymId,
          idToken: idToken,
          level: backendResponse.data?.level,
          completedQuestionnaire: backendResponse.data?.completedQuestionnaire,
        );
        return {
          'success': true,
          'userId': user.uid,
          'gymId': backendResponse.data?.gymId,
          'user': user,
          'completedQuestionnaire':
              backendResponse.data?.completedQuestionnaire,
        };
      }
      throw Exception('Registration failed. Try again later.');
    } on GoogleSignInException catch (e) {
      // User canceled or other sign-in error
      if (e.code == GoogleSignInExceptionCode.canceled) return null;
      _logger.severe('GoogleSignIn error: ${e.code}', e);
      return {'success': false, 'error': e.description ?? e.code};
    } catch (e) {
      _logger.severe('Sign in error', e);
      return {'success': false, 'error': e.toString()};
    }
  }

  /// Sign out
  Future<void> signOut() async {
    await _auth.signOut();
    // On mobile, also sign out of GoogleSignIn plugin
    if (!kIsWeb) {
      await GoogleSignIn.instance.signOut();
    }
    await clearLocalUserData();
  }

  /// Get current Firebase user
  fb_auth.User? get currentUser => _auth.currentUser;

  /// Check if user is signed in
  bool get isSignedIn => _auth.currentUser != null;

  /// Fetch current user info from backend; if token expired, refresh and retry once
  Future<bool> fetchUserOnAppStartWithRetry() async {
    try {
      if (!isSignedIn) return false;
      final res = await _userApiService.userPartialRead();
      if (res.success) {
        final user = _auth.currentUser;
        if (user != null) {
          final token = await user.getIdToken();
          await saveLocalUserData(
            userId: user.uid,
            gymId: res.data?.gymId,
            idToken: token,
            level: res.data?.level,
            completedQuestionnaire: res.data?.completedQuestionnaire,
          );
        }
        return true;
      }

      // If unauthorized/forbidden, refresh and retry once
      if (res.status == 401 || res.status == 403) {
        _logger.info(
          'Token likely expired. Refreshing and retrying userPartialRead.',
        );
        final user = _auth.currentUser;
        if (user == null) return false;
        final fresh = await user.getIdToken(true);
        if (fresh == null) return false;
        await _userAuthStorage.update(
          copyWithFn: (u) => u.copyWith(authToken: fresh),
        );

        final retry = await _userApiService.userPartialRead();
        if (retry.success) {
          await saveLocalUserData(
            userId: user.uid,
            gymId: retry.data?.gymId,
            idToken: fresh,
            level: retry.data?.level,
            completedQuestionnaire: retry.data?.completedQuestionnaire,
          );
          return true;
        }
      }

      _logger.warning(
        'fetchUserOnAppStartWithRetry failed: status=${res.status}, error=${res.error}, message=${res.message}',
      );
      return false;
    } catch (e, st) {
      _logger.severe('fetchUserOnAppStartWithRetry error', e, st);
      return false;
    }
  }
}
