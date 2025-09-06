import 'package:firebase_auth/firebase_auth.dart';
import 'dart:async';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:flutter/foundation.dart';

import 'logger_service.dart';
import 'hive/user_auth_lss.dart';
import './api/user_api_service.dart';

class AuthService {
  static final AuthService _instance = AuthService._internal();
  factory AuthService() => _instance;
  AuthService._internal();

  final FirebaseAuth _auth = FirebaseAuth.instance;
  final UserApiService _userApiService = UserApiService();

  final AppLogger _logger = AppLogger();

  final _userAuthStorage = UserAuthLocalStorageService();

  /// Check locally saved user data (userId and gymId exist)
  Future<Map<String, String?>> getLocalUserData() async {
    final hive = await _userAuthStorage.load();
    _logger.debug('Retrieved userId from Hive: ${hive?.userId}');
    return {
      'userId': hive?.userId,
      'gymId': hive?.gymId,
      'auth_token': hive?.authToken,
  'is_guest': hive?.isGuest == true ? 'true' : null,
    };
  }

  /// Save user data locally
  Future<void> saveLocalUserData({
    String? userId,
    String? gymId,
    String? idToken,
    bool? isGuest,
  }) async {
    await _userAuthStorage.save(
      userId: userId,
      gymId: gymId,
      authToken: idToken,
      isGuest: isGuest,
    );
  }

  Future<void> markGuestSelected(String deviceId) async {
    // DeviceId not stored here (kept by DeviceIdentityService), just set guest flag.
    await _userAuthStorage.save(isGuest: true);
  }

  /// Clear local user data
  Future<void> clearLocalUserData() async {
    await _userAuthStorage.clear();
  }

  /// Sign in with Google and register/login with backend
  Future<Map<String, dynamic>?> signInWithGoogle() async {
    try {
      // Sign in via Google
      UserCredential userCredential;
      if (kIsWeb) {
        // Web: use Firebase Auth popup
        final provider = GoogleAuthProvider();
        provider.addScope('email');
        provider.addScope('profile');
        userCredential = await _auth.signInWithPopup(provider);
      } else {
        await GoogleSignIn.instance.initialize();
        // Mobile: sign in with google_sign_in plugin
        final googleUser = await GoogleSignIn.instance.authenticate();
        final googleAuth = googleUser.authentication;
        // Create credential with ID token
        final credential = GoogleAuthProvider.credential(
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
        );
        return {
          'success': true,
          'userId': user.uid,
          'gymId': backendResponse.data?.gymId,
          'user': user,
        };
      }
      throw Exception('Registration failed. Try again later.');
    } on GoogleSignInException catch (e) {
      // User canceled or other sign-in error
      if (e.code == GoogleSignInExceptionCode.canceled) return null;
      _logger.error('GoogleSignIn error: ${e.code}', e);
      return {'success': false, 'error': e.description ?? e.code};
    } catch (e) {
      _logger.error('Sign in error', e);
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
  User? get currentUser => _auth.currentUser;

  /// Check if user is signed in
  bool get isSignedIn => _auth.currentUser != null;

  /// Fetch current user info from backend; if token expired, refresh and retry once
  Future<bool> fetchUserOnAppStartWithRetry() async {
    try {
      final res = await _userApiService.userPartialRead();
      if (res.success) {
        final user = _auth.currentUser;
        if (user != null) {
          final token = await user.getIdToken();
          await saveLocalUserData(
            userId: user.uid,
            gymId: res.data?.gymId,
            idToken: token,
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
        await _userAuthStorage.save(authToken: fresh);

        final retry = await _userApiService.userPartialRead();
        if (retry.success) {
          await saveLocalUserData(
            userId: user.uid,
            gymId: retry.data?.gymId,
            idToken: fresh,
          );
          return true;
        }
      }

      _logger.warning(
        'fetchUserOnAppStartWithRetry failed: status=${res.status}, error=${res.error}, message=${res.message}',
      );
      return false;
    } catch (e, st) {
      _logger.error('fetchUserOnAppStartWithRetry error', e, st);
      return false;
    }
  }
}
