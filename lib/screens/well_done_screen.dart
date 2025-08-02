import 'package:flutter/material.dart';
import 'package:gympad/services/analytics_service.dart';
import 'package:url_launcher/url_launcher.dart';
import '../constants/app_styles.dart';
import '../models/exercise.dart';
import '../models/workout_set.dart';
import '../widgets/workout_sets_table.dart';

class WellDoneScreen extends StatefulWidget {
  final Exercise exercise;
  final List<WorkoutSet> completedSets;

  const WellDoneScreen({
    Key? key,
    required this.exercise,
    required this.completedSets,
  }) : super(key: key);

  @override
  State<WellDoneScreen> createState() => _WellDoneScreenState();
}

class _WellDoneScreenState extends State<WellDoneScreen> {

  @override
  void initState() {
    super.initState();
    _sendAnalyticsEvent();
  }

  Future<void> _sendAnalyticsEvent() async {
    await AnalyticsService.instance.incrementExerciseComplete();
  }

  Future<void> _sendReview() async {
    const phoneNumber = '+972548946639';
    const message =
        'Hi! I just used your GymPad app and wanted to share my feedback.';
    final uri = Uri.parse(
      'https://wa.me/$phoneNumber?text=${Uri.encodeComponent(message)}',
    );

    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.background,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.close, color: AppColors.primary),
          onPressed:
              () => Navigator.of(context).popUntil((route) => route.isFirst),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            const SizedBox(height: 20),

            // Well Done title
            Text(
              'Well Done, big guy!',
              style: AppTextStyles.titleLarge.copyWith(
                fontSize: 40,
                fontStyle: FontStyle.italic,
              ),
              textAlign: TextAlign.center,
            ),

            const SizedBox(height: 40),

            // Exercise completed info
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: AppColors.accent.withValues(alpha: 0.2),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: AppColors.accent, width: 2),
              ),
              child: Column(
                children: [
                  Text('Exercise Completed', style: AppTextStyles.titleMedium),
                  const SizedBox(height: 8),
                  Text(
                    widget.exercise.name,
                    style: AppTextStyles.bodyLarge.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '${widget.completedSets.length} sets completed',
                    style: AppTextStyles.bodyMedium.copyWith(
                      color: AppColors.textSecondary,
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 32),

            // Workout sets table
            WorkoutSetsTable(sets: widget.completedSets),

            const SizedBox(height: 40),

            // Send review button
            SizedBox(
              width: double.infinity,
              height: 56,
              child: ElevatedButton(
                onPressed: _sendReview,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: Text(
                  'Send a Review',
                  style: AppTextStyles.button.copyWith(
                    color: AppColors.white,
                    fontSize: 18,
                  ),
                ),
              ),
            ),

            const SizedBox(height: 24),

            // Disclaimer text
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Text(
                'This is a test application. We hope you enjoyed it! All of the data is going to be saved on your device, and not transferred anywhere.',
                style: AppTextStyles.bodySmall.copyWith(
                  fontStyle: FontStyle.italic,
                ),
                textAlign: TextAlign.center,
              ),
            ),

            const SizedBox(height: 40),
          ],
        ),
      ),
    );
  }
}
