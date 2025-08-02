import 'package:flutter/material.dart';
import '../constants/app_styles.dart';
import '../services/data_service.dart';
import 'exercise_screen.dart';

class DevExerciseSelector extends StatefulWidget {
  const DevExerciseSelector({super.key});

  @override
  State<DevExerciseSelector> createState() => _DevExerciseSelectorState();
}

class _DevExerciseSelectorState extends State<DevExerciseSelector> {
  final DataService _dataService = DataService();
  
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.background,
        elevation: 0,
        title: Text(
          'Dev: Select Exercise',
          style: AppTextStyles.appBarTitle,
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Development Mode',
              style: AppTextStyles.titleLarge,
            ),
            const SizedBox(height: 8),
            Text(
              'Select an exercise to test without NFC scanning',
              style: AppTextStyles.bodyMedium.copyWith(
                color: AppColors.textSecondary,
              ),
            ),
            const SizedBox(height: 32),
            Expanded(
              child: ListView(
                children: [
                  _buildExerciseOption(
                    'Bicep Curls',
                    'Elite Fitness Center',
                    'GYM_ABC',
                    'bicep_curls',
                  ),
                  _buildExerciseOption(
                    'Tricep Extensions',
                    'Urban Strength Hub',
                    'GYM_XYZ',
                    'tricep_extensions',
                  ),
                  _buildExerciseOption(
                    'Shoulder Press Machine',
                    'Elite Fitness Center',
                    'GYM_ABC',
                    'shoulder_press_machine',
                  ),
                  _buildExerciseOption(
                    'Leg Press',
                    'Urban Strength Hub',
                    'GYM_XYZ',
                    'leg_press',
                  ),
                  _buildExerciseOption(
                    'Barbell Squats',
                    'Elite Fitness Center',
                    'GYM_ABC',
                    'squats',
                  ),
                  _buildExerciseOption(
                    'Bench Press',
                    'Urban Strength Hub',
                    'GYM_XYZ',
                    'bench_press',
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildExerciseOption(
    String exerciseName,
    String gymName,
    String gymId,
    String exerciseId,
  ) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      child: Material(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(12),
        elevation: 2,
        child: InkWell(
          borderRadius: BorderRadius.circular(12),
          onTap: () => _navigateToExercise(gymId, exerciseId),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    color: AppColors.primary,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(
                    Icons.fitness_center,
                    color: AppColors.white,
                    size: 24,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        exerciseName,
                        style: AppTextStyles.bodyLarge.copyWith(
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        gymName,
                        style: AppTextStyles.bodySmall.copyWith(
                          color: AppColors.textSecondary,
                        ),
                      ),
                    ],
                  ),
                ),
                Icon(
                  Icons.arrow_forward_ios,
                  color: AppColors.textSecondary,
                  size: 16,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _navigateToExercise(String gymId, String exerciseId) {
    final gym = _dataService.getGym(gymId);
    final exercise = _dataService.getExercise(exerciseId);

    if (gym == null || exercise == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error loading gym or exercise data'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => ExerciseScreen(
          gym: gym,
          exercise: exercise,
        ),
      ),
    );
  }
}
