import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../constants/app_styles.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../blocs/auth/auth_bloc.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  void _signInWithGoogle() {
    context.read<AuthBloc>().add(AuthSignInRequested());
  }

  void _continueAsGuest() {
    context.read<AuthBloc>().add(AuthGuestRequested());
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
                onPressed: () => context.pop(),
                child: Text('OK', style: AppTextStyles.button),
              ),
            ],
          ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final authState = context.watch<AuthBloc>().state;
    return Scaffold(
      backgroundColor: AppColors.background,
      body: BlocListener<AuthBloc, AuthState>(
        listener: (context, state) {
          if (state is AuthAuthenticated || state is AuthGuest) {
            context.pushReplacement('/main');
          } else if (state is AuthError) {
            _showErrorDialog(state.message);
          }
        },
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

              // Sign In & Guest buttons / progress
              if (authState is AuthLoading) ...[
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
                ),
              ] else ...[
                Column(
                  children: [
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
                    const SizedBox(height: 16),
                    Text('or', style: AppTextStyles.bodySmall.copyWith(color: AppColors.textSecondary)),
                    const SizedBox(height: 16),
                    Container(
                      width: double.infinity,
                      height: 48,
                      margin: const EdgeInsets.symmetric(horizontal: 40),
                      child: OutlinedButton(
                        onPressed: _continueAsGuest,
                        style: OutlinedButton.styleFrom(
                          foregroundColor: AppColors.primary,
                          side: BorderSide(color: AppColors.primary, width: 1.5),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                        ),
                        child: Text(
                          'Continue as Guest',
                          style: AppTextStyles.button.copyWith(
                            color: AppColors.primary,
                            fontSize: 16,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ],

              const SizedBox(height: 40),

              // Terms and privacy info
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Text(
                  'By signing in (or continuing as guest), you agree to our Terms of Service and Privacy Policy. Some features are limited in guest mode.',
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
