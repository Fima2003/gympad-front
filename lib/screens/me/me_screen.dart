import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:gympad/blocs/auth/auth_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:gympad/constants/app_styles.dart';

class MeScreen extends StatefulWidget {
  const MeScreen({super.key});

  @override
  State<MeScreen> createState() => _MeScreenState();
}

class _MeScreenState extends State<MeScreen> {
  @override
  Widget build(BuildContext context) {
    return BlocBuilder<AuthBloc, AuthState>(
      builder: (context, state) {
        Widget content;
        if (state is AuthAuthenticated) {
          content = Center(child: Text('User ID: ${state.userId}'));
        } else if (state is AuthGuest) {
          content = Center(
            child: Text('Guest User - Device ID: ${state.deviceId}'),
          );
        } else if (state is AuthUnauthenticated) {
          content = const Center(child: Text('Not signed in'));
        } else if (state is AuthLoading) {
          content = const Center(child: CircularProgressIndicator());
        } else if (state is AuthError) {
          content = Center(child: Text('Error: ${state.message}'));
        } else {
          content = const SizedBox.shrink();
        }

        return Column(
          children: [
            Padding(
              padding: const EdgeInsets.all(16),
              child: SizedBox(
                width: double.infinity,
                child:
                    (state is AuthAuthenticated &&
                            (state.completedQuestionnaire == null ||
                                state.completedQuestionnaire == false))
                        ? ElevatedButton(
                          onPressed:
                              () => context.go('/questionnaire?force=true'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppColors.primary,
                            foregroundColor: AppColors.white,
                            shape: const StadiumBorder(),
                            minimumSize: const Size.fromHeight(48),
                          ),
                          child: const Text('Fill out questionnaire'),
                        )
                        : const SizedBox(),
              ),
            ),
            Expanded(child: content),
          ],
        );
      },
    );
  }
}
