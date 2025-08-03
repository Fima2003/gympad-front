import 'package:flutter/material.dart';
import '../constants/app_styles.dart';
import '../services/auth_service.dart';
import 'main_screen.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final AuthService _authService = AuthService();
  bool _isLoading = false;

  Future<void> _signInWithGoogle() async {
    setState(() => _isLoading = true);

    try {
      final result = await _authService.signInWithGoogle();

      if (result != null && result['success'] == true) {
        // Navigate to main screen
        if (mounted) {
          Navigator.of(context).pushReplacement(
            MaterialPageRoute(builder: (context) => const MainScreen()),
          );
        }
      } else if (result != null && result['success'] == false) {
        // Show error
        if (mounted) {
          _showErrorDialog(result['error'] ?? 'Unknown error occurred');
        }
      }
      // If result is null, user canceled the sign-in
    } catch (e) {
      if (mounted) {
        _showErrorDialog('An unexpected error occurred: $e');
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  void _showErrorDialog(String message) {
    showDialog(
      context: context,
      builder:
          (context) => AlertDialog(
            title: Text('Sign In Error', style: AppTextStyles.titleMedium),
            content: Text(message, style: AppTextStyles.bodyMedium),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(),
                child: Text('OK', style: AppTextStyles.button),
              ),
            ],
          ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(40),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // Sports visual/icon
              Container(
                width: 120,
                height: 120,
                decoration: BoxDecoration(
                  color: AppColors.primary,
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  Icons.fitness_center,
                  size: 60,
                  color: AppColors.accent,
                ),
              ),

              const SizedBox(height: 40),

              // App title
              Text(
                'GymPad',
                style: AppTextStyles.titleLarge.copyWith(
                  fontSize: 48,
                  fontStyle: FontStyle.italic,
                ),
              ),

              const SizedBox(height: 16),

              // Subtitle
              Text(
                'Your personal workout companion',
                style: AppTextStyles.bodyLarge.copyWith(
                  color: AppColors.textSecondary,
                ),
                textAlign: TextAlign.center,
              ),

              const SizedBox(height: 60),

              // Sign In with Google button
              if (_isLoading)
                Column(
                  children: [
                    CircularProgressIndicator(color: AppColors.primary),
                    const SizedBox(height: 16),
                    Text(
                      'Signing you in...',
                      style: AppTextStyles.bodyMedium.copyWith(
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ],
                )
              else
                Container(
                  width: double.infinity,
                  height: 56,
                  margin: const EdgeInsets.symmetric(horizontal: 20),
                  child: ElevatedButton.icon(
                    onPressed: _signInWithGoogle,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      foregroundColor: AppColors.accent,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      elevation: 2,
                    ),
                    icon: Icon(Icons.login, size: 24, color: AppColors.accent),
                    label: Text(
                      'Sign In with Google',
                      style: AppTextStyles.button.copyWith(
                        color: AppColors.accent,
                        fontSize: 18,
                      ),
                    ),
                  ),
                ),

              const SizedBox(height: 40),

              // Terms and privacy info
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Text(
                  'By signing in, you agree to our Terms of Service and Privacy Policy',
                  style: AppTextStyles.bodySmall.copyWith(
                    fontStyle: FontStyle.italic,
                  ),
                  textAlign: TextAlign.center,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
