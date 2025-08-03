import 'package:firebase_auth/firebase_auth.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:http/http.dart' as http;
import 'dart:async';
import 'dart:convert';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:flutter/foundation.dart';

class AuthService {
  static final AuthService _instance = AuthService._internal();
  factory AuthService() => _instance;
  AuthService._internal();

  final FirebaseAuth _auth = FirebaseAuth.instance;

  // Keys for SharedPreferences
  static const String _userIdKey = 'userId';
  static const String _gymIdKey = 'gymIdKey';

  /// Check locally saved user data (userId and gymId exist)
  Future<Map<String, String?>> getLocalUserData() async {
    final prefs = await SharedPreferences.getInstance();
    return {
      'userId': prefs.getString(_userIdKey),
      'gymId': prefs.getString(_gymIdKey),
    };
  }

  /// Save user data locally
  Future<void> saveLocalUserData(String userId, String gymId) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_userIdKey, userId);
    await prefs.setString(_gymIdKey, gymId);
  }

  /// Clear local user data
  Future<void> clearLocalUserData() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_userIdKey);
    await prefs.remove(_gymIdKey);
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
        final googleAuth = await googleUser.authentication;
        // Create credential with ID token
        final credential = GoogleAuthProvider.credential(
          idToken: googleAuth.idToken,
        );
        userCredential = await _auth.signInWithCredential(credential);
      }
      final user = userCredential.user;
      if (user == null) throw Exception('Google sign-in failed');
      // Register/login with backend
      final backendResponse = await _registerWithBackend(
        user.uid,
        user.displayName ?? '',
        user.email ?? '',
        user.photoURL ?? '',
      );
      if (backendResponse != null && backendResponse['success'] == true) {
        await saveLocalUserData(user.uid, backendResponse['gymId'] ?? '');
        return {
          'success': true,
          'userId': user.uid,
          'gymId': backendResponse['gymId'],
          'user': user,
        };
      }
      throw Exception(
        'Backend registration failed: ${backendResponse?['error'] ?? 'Unknown error'}',
      );
    } on GoogleSignInException catch (e) {
      // User canceled or other sign-in error
      if (e.code == GoogleSignInExceptionCode.canceled) return null;
      print('GoogleSignIn error: ${e.code}');
      return {'success': false, 'error': e.description ?? e.code};
    } catch (e) {
      print('Sign in error: $e');
      return {'success': false, 'error': e.toString()};
    }
  }

  /// Register/login with backend
  Future<Map<String, dynamic>?> _registerWithBackend(
    String userId,
    String displayName,
    String email,
    String photoUrl,
  ) async {
    try {
      return {"success": true};
      final response = await http.post(
        Uri.parse('https://be.gympad.co/sign-up'),
        headers: {'Content-Type': 'application/json'},
        body: json.encode({
          'userId': userId,
          'displayName': displayName,
          'email': email,
          'photoUrl': photoUrl,
        }),
      );

      if (response.statusCode == 200) {
        return json.decode(response.body);
      } else {
        print('Backend error: ${response.statusCode} - ${response.body}');
        return {
          'success': false,
          'error': 'Backend error: ${response.statusCode}',
        };
      }
    } catch (e) {
      print('Network error: $e');
      return {'success': false, 'error': 'Network error: $e'};
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
}
