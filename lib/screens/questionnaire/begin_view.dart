part of 'questionnaire_screen.dart';

class _BeginView extends StatelessWidget {
  final VoidCallback onStart;
  final VoidCallback onSkip;
  const _BeginView({required this.onStart, required this.onSkip});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 16),
          Text(
            'Let\'s personalize your GymPad',
            style: AppTextStyles.titleLarge,
          ),
          const SizedBox(height: 12),
          Text(
            'We\'ll ask 12 short questions to tailor workouts and recommendations to your goals and experience. This takes about 3-5 minutes.',
            style: AppTextStyles.bodyMedium.copyWith(
              color: AppColors.textSecondary,
            ),
          ),
          const Spacer(),
          Row(
            children: [
              Expanded(
                child: ElevatedButton(
                  onPressed: onStart,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    foregroundColor: AppColors.white,
                    shape: const StadiumBorder(),
                    minimumSize: const Size.fromHeight(48),
                  ),
                  child: const Text('Start'),
                ),
              ),
              const SizedBox(width: 12),
              TextButton(
                onPressed: onSkip,
                style: TextButton.styleFrom(foregroundColor: AppColors.primary),
                child: const Text('Do it later'),
              ),
            ],
          ),
          const SizedBox(height: 16),
        ],
      ),
    );
  }
}
