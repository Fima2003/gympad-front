import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:gympad/blocs/analytics/analytics_bloc.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:go_router/go_router.dart';
import '../constants/app_styles.dart';
import '../models/workout.dart';
import '../widgets/workout_exercises_table.dart';

class WellDoneWorkoutScreen extends StatefulWidget {
  final Workout workout;

  const WellDoneWorkoutScreen({super.key, required this.workout});

  @override
  State<WellDoneWorkoutScreen> createState() => _WellDoneWorkoutScreenState();
}

class _WellDoneWorkoutScreenState extends State<WellDoneWorkoutScreen> {
  @override
  void initState() {
    super.initState();
    _sendAnalyticsEvent();
  }

  Future<void> _sendAnalyticsEvent() async {
    context.read<AnalyticsBloc>().add(ACompletedWorkout());
  }

  Future<void> _sendReview() async {
    const phoneNumber = '+972548946639';
    const message =
        'Hi! I just used your GymPad app and wanted to share my feedback about my workout.';
    final uri = Uri.parse(
      'https://wa.me/$phoneNumber?text=${Uri.encodeComponent(message)}',
    );

    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    }
  }

  String _formatDuration(Duration duration) {
    String twoDigits(int n) => n.toString().padLeft(2, "0");
    String twoDigitMinutes = twoDigits(duration.inMinutes.remainder(60));
    String twoDigitSeconds = twoDigits(duration.inSeconds.remainder(60));

    if (duration.inHours > 0) {
      return "${twoDigits(duration.inHours)}:$twoDigitMinutes:$twoDigitSeconds";
    } else {
      return "$twoDigitMinutes:$twoDigitSeconds";
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20).copyWith(top: 60),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            // Celebration message
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: AppColors.accent.withValues(alpha: 0.2),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: AppColors.accent, width: 2),
              ),
              child: Column(
                children: [
                  Icon(Icons.celebration, size: 64, color: AppColors.primary),
                  const SizedBox(height: 16),
                  Text(
                    'Well Done!',
                    style: AppTextStyles.titleLarge.copyWith(fontSize: 32),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'You completed your workout!',
                    style: AppTextStyles.bodyLarge,
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            ),
            const SizedBox(height: 32),

            // Workout Summary Stats
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: AppColors.white,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: AppColors.primary.withValues(alpha: 0.2),
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Workout Summary', style: AppTextStyles.titleMedium),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      Expanded(
                        child: _buildStatItem(
                          'Duration',
                          _formatDuration(widget.workout.totalDuration),
                          Icons.timer,
                        ),
                      ),
                      Expanded(
                        child: _buildStatItem(
                          'Exercises',
                          widget.workout.totalExercises.toString(),
                          Icons.fitness_center,
                        ),
                      ),
                      Expanded(
                        child: _buildStatItem(
                          'Total Sets',
                          widget.workout.totalSets.toString(),
                          Icons.format_list_numbered,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),

            // Workout exercises table
            WorkoutExercisesTable(exercises: widget.workout.exercises),
            const SizedBox(height: 32),

            // Action buttons
            Row(
              children: [
                Expanded(
                  child: ElevatedButton(
                    onPressed: () {
                      // Navigate back to main via GoRouter to keep page-based navigation consistent.
                      if (context.canPop()) {
                        // If there is intermediate stack (e.g., nested), clear to main.
                        context.go('/main');
                      } else {
                        context.go('/main');
                      }
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      foregroundColor: AppColors.white,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: Text(
                      'Back to Home',
                      style: AppTextStyles.button.copyWith(
                        color: AppColors.white,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: ElevatedButton(
                    onPressed: _sendReview,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.accent,
                      foregroundColor: AppColors.primary,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: Text(
                      'Send Feedback',
                      style: AppTextStyles.button.copyWith(
                        color: AppColors.primary,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            // Save Workout button (free workout only)
            if (widget.workout.isFreeWorkout)
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () {
                    // Use GoRouter; workout passed via extra.
                    context.push('/workout/free/save', extra: widget.workout);
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    foregroundColor: AppColors.white,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: Text(
                    'Save Workout',
                    style: AppTextStyles.button.copyWith(
                      color: AppColors.white,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatItem(String title, String value, IconData icon) {
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: AppColors.primary.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(icon, color: AppColors.primary, size: 24),
        ),
        const SizedBox(height: 8),
        Text(value, style: AppTextStyles.titleMedium.copyWith(fontSize: 18)),
        Text(title, style: AppTextStyles.bodySmall),
      ],
    );
  }
}
