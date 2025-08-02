import 'package:firebase_auth/firebase_auth.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'dart:async';
import 'package:flutter/foundation.dart';

class AuthService {
  static final AuthService _instance = AuthService._internal();
  factory AuthService() => _instance;
  AuthService._internal();

  final FirebaseAuth _auth = FirebaseAuth.instance;

  // Keys for SharedPreferences
  static const String _userIdKey = 'userId';
  static const String _gymIdKey = 'gymIdKey';

  /// Check if user is locally saved (userId and gymId exist)
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
      User? googleUser;
      bool authSuccessful = false;

      // Handle different platforms
      if (kIsWeb) {
        // For web platform, try a simpler approach first
        try {
          GoogleAuthProvider authProvider = GoogleAuthProvider();
          UserCredential userCredential = await _auth.signInWithPopup(
            authProvider,
          );
          authSuccessful = userCredential.user != null;
          googleUser = userCredential.user;
        } catch (e) {
          print('Web authentication error: $e');
          // If the new API doesn't work on web, provide helpful error
          return {
            'success': false,
            'error':
                'Google Sign-In on web requires proper configuration. Please ensure the Google Sign-In JavaScript SDK is loaded and your web client ID is configured correctly.',
          };
        }
      } else {
        // For mobile platforms - simplified approach
        try {
          // For mobile, we'll use Firebase Auth directly with Google provider
          // This bypasses the complex Google Sign-In API issues
          GoogleAuthProvider googleProvider = GoogleAuthProvider();
          
          // Add scopes if needed
          googleProvider.addScope('email');
          googleProvider.addScope('profile');
          
          // Sign in with redirect (works better on mobile)
          final UserCredential userCredential = await _auth.signInWithProvider(googleProvider);
          authSuccessful = userCredential.user != null;
          googleUser = userCredential.user;
        } catch (e) {
          print('Mobile authentication error: $e');
          return {
            'success': false,
            'error': 'Mobile authentication failed: $e. Please ensure Google Sign-In is properly configured.',
          };
        }
      }

      // Check if authentication was successful
      if (!authSuccessful) {
        return null; // User canceled or authentication failed
      }

      if (googleUser == null) {
        throw Exception('Failed to create Firebase user');
      }

      // Send user details to backend
      // final backendResponse = await _registerWithBackend(
      //   googleUser.uid,
      //   googleUser.displayName ?? '',
      //   googleUser.email ?? '',
      //   googleUser.photoURL ?? '',
      // );

      const Map<String, dynamic> backendResponse = {
        'success': true,
        'gymId': 'exampleGymId', // Simulated response
      }; // Simulated backend response for testing

      if (backendResponse != null && backendResponse['success'] == true) {
        // Save user data locally
        await saveLocalUserData(googleUser.uid, backendResponse['gymId'] ?? '');

        return {
          'success': true,
          'userId': googleUser.uid,
          'gymId': backendResponse['gymId'],
          'user': googleUser,
          'googleUser': googleUser,
        };
      } else {
        throw Exception(
          'Backend registration failed: ${backendResponse?['error'] ?? 'Unknown error'}',
        );
      }
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
    await clearLocalUserData();
  }

  /// Get current Firebase user
  User? get currentUser => _auth.currentUser;

  /// Check if user is signed in
  bool get isSignedIn => _auth.currentUser != null;
}
