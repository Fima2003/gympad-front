import 'package:flutter/material.dart';
import '../constants/app_styles.dart';
import '../models/workout_exercise.dart';

class WorkoutExercisesTable extends StatelessWidget {
  final List<WorkoutExercise> exercises;

  const WorkoutExercisesTable({super.key, required this.exercises});

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
    if (exercises.isEmpty) {
      return Container(
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: AppColors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: AppColors.primary.withValues(alpha: 0.2)),
        ),
        child: Text(
          'No exercises recorded',
          style: AppTextStyles.bodyMedium.copyWith(
            color: AppColors.textSecondary,
          ),
          textAlign: TextAlign.center,
        ),
      );
    }

    return Container(
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.primary.withValues(alpha: 0.2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: Text(
              'Exercises Completed',
              style: AppTextStyles.titleMedium,
            ),
          ),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: DataTable(
              columnSpacing: 16,
              horizontalMargin: 16,
              headingRowColor: WidgetStateProperty.all(
                AppColors.primary.withValues(alpha: 0.1),
              ),
              columns: [
                DataColumn(
                  label: Text(
                    'Exercise',
                    style: AppTextStyles.bodyMedium.copyWith(
                      fontWeight: FontWeight.w600,
                      color: AppColors.primary,
                    ),
                  ),
                ),
                DataColumn(
                  label: Text(
                    'Sets',
                    style: AppTextStyles.bodyMedium.copyWith(
                      fontWeight: FontWeight.w600,
                      color: AppColors.primary,
                    ),
                  ),
                ),
                DataColumn(
                  label: Text(
                    'Duration',
                    style: AppTextStyles.bodyMedium.copyWith(
                      fontWeight: FontWeight.w600,
                      color: AppColors.primary,
                    ),
                  ),
                ),
                DataColumn(
                  label: Text(
                    'Avg Weight',
                    style: AppTextStyles.bodyMedium.copyWith(
                      fontWeight: FontWeight.w600,
                      color: AppColors.primary,
                    ),
                  ),
                ),
              ],
              rows: exercises.map((exercise) {
                return DataRow(
                  cells: [
                    DataCell(
                      SizedBox(
                        width: 120,
                        child: Text(
                          exercise.name,
                          style: AppTextStyles.bodyMedium,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ),
                    DataCell(
                      Text(
                        exercise.totalSets.toString(),
                        style: AppTextStyles.bodyMedium,
                      ),
                    ),
                    DataCell(
                      Text(
                        _formatDuration(exercise.duration),
                        style: AppTextStyles.bodyMedium,
                      ),
                    ),
                    DataCell(
                      Text(
                        '${exercise.averageWeight.toStringAsFixed(1)} kg',
                        style: AppTextStyles.bodyMedium,
                      ),
                    ),
                  ],
                );
              }).toList(),
            ),
          ),
        ],
      ),
    );
  }
}
