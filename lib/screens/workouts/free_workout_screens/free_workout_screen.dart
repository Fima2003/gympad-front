import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import '../../../blocs/workout/workout_bloc.dart';
import '../../../constants/app_styles.dart';
import '../../../widgets/button.dart';

class FreeWorkoutScreen extends StatelessWidget {
  const FreeWorkoutScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<WorkoutBloc, WorkoutState>(
      builder: (context, state) {
        final inRunPhase =
            state is WorkoutRunInSet ||
            state is WorkoutRunRest ||
            state is WorkoutRunFinishing;
        final hasPlan =
            (state is WorkoutRunInSet && state.workoutToFollow != null) ||
            (state is WorkoutRunRest && state.workoutToFollow != null);
        return Center(
          child: Padding(
            padding: const EdgeInsets.all(40),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  'Welcome to GymPad!',
                  style: AppTextStyles.titleLarge.copyWith(
                    fontSize: 32,
                    fontStyle: FontStyle.italic,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 24),
                Text(
                  inRunPhase
                      ? 'You have a workout in progress!'
                      : 'Ready to start your workout?',
                  style: AppTextStyles.bodyLarge.copyWith(
                    color: AppColors.textSecondary,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 40),
                Container(
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    color: AppColors.accent.withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: AppColors.accent, width: 2),
                  ),
                  child: Column(
                    children: [
                      Icon(Icons.nfc, size: 64, color: AppColors.primary),
                      const SizedBox(height: 16),
                      Text(
                        'Scan NFC tag',
                        style: AppTextStyles.bodyLarge.copyWith(
                          fontWeight: FontWeight.w600,
                          color: AppColors.primary,
                        ),
                      ),
                    ],
                  ),
                ),

                Container(
                  width: double.infinity,
                  margin: EdgeInsets.symmetric(vertical: 10),
                  child: Text(
                    'or',
                    style: AppTextStyles.bodyLarge.copyWith(
                      color: AppColors.textSecondary,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ),

                // Start Workout Button
                if (!inRunPhase)
                  GymPadButton(
                    label: 'START A WORKOUT',
                    onPressed: () {
                      context.push('/workout/free/run');
                    },
                    fullWidth: true,
                  )
                else
                  // Continue Workout Button (route differs if following a custom workout)
                  GymPadButton(
                    label: hasPlan ? 'RESUME WORKOUT' : 'CONTINUE WORKOUT',
                    onPressed: () {
                      if (hasPlan) {
                        context.push('/workout/custom/run');
                      } else {
                        context.push('/workout/free/run');
                      }
                    },
                    variant: 'accent',
                    fullWidth: true,
                  ),
              ],
            ),
          ),
        );
      },
    );
  }
}
