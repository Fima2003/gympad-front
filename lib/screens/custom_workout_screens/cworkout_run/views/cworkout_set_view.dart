import 'package:flutter/material.dart';

import '../../../../constants/app_styles.dart';
import '../../../../models/workout_set.dart';
import '../../../../widgets/reps_selector.dart';
import '../../../../widgets/velocity_weight_selector.dart';

enum FinishType { set, exercise, workout }

class CWorkoutRunView extends StatefulWidget {
  final String workoutTitle;
  final String exerciseName;
  final int totalSets;
  final double initialWeight;
  final int suggestedReps;
  final List<WorkoutSet> completedSets;
  final void Function(
    double selectedWeight,
    int selectedReps,
    Duration duration,
  )
  onFinish;
  final FinishType finishType;
  final Duration elapsed;
  final bool isRunning; // always true for now (timer managed by bloc)

  const CWorkoutRunView({
    super.key,
    required this.workoutTitle,
    required this.exerciseName,
    required this.totalSets,
    required this.initialWeight,
    required this.suggestedReps,
    required this.completedSets,
    required this.onFinish,
    required this.finishType,
    required this.elapsed,
    required this.isRunning,
  });

  @override
  State<CWorkoutRunView> createState() => _CWorkoutRunViewState();
}

class _CWorkoutRunViewState extends State<CWorkoutRunView> {
  late double _selectedWeight;

  @override
  void initState() {
    super.initState();
    _selectedWeight = widget.initialWeight;
  }

  @override
  void didUpdateWidget(covariant CWorkoutRunView oldWidget) {
    super.didUpdateWidget(oldWidget);
    // If exercise changed, re-seed weight to new suggested initial.
    if (oldWidget.exerciseName != widget.exerciseName) {
      _selectedWeight = widget.initialWeight;
    }
  }

  int get currentSetIdx => widget.completedSets.length;

  void _showRepsSelector(BuildContext context) {
    // Stop not needed (bloc controls timer) but keep placeholder for future pause.
    showDialog<int>(
      context: context,
      barrierDismissible: true,
      builder: (BuildContext context) {
        return RepsSelector(initialReps: widget.suggestedReps);
      },
    ).then((reps) {
      if (reps == null) {
        return;
      }
      final duration = widget.elapsed;
      widget.onFinish(_selectedWeight, reps, duration);
    });
  }

  @override
  Widget build(BuildContext context) {
    const double buttonWidth = 280.0;
    // weight kept in state; local variable not needed.

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.background,
        elevation: 0,
        automaticallyImplyLeading: false,
        title: Text(
          widget.workoutTitle,
          style: AppTextStyles.titleMedium.copyWith(
            color: AppColors.primary,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: Column(
            children: [
              // Exercise name
              Text(
                widget.exerciseName,
                style: AppTextStyles.titleLarge.copyWith(
                  color: AppColors.primary,
                  fontWeight: FontWeight.bold,
                ),
                textAlign: TextAlign.center,
              ),

              const SizedBox(height: 8),

              // Set info
              Text(
                'Set ${currentSetIdx + 1} of ${widget.totalSets}',
                style: AppTextStyles.bodyLarge.copyWith(
                  color: AppColors.primary.withValues(alpha: 0.7),
                ),
              ),

              const SizedBox(height: 24),

              // Timer display
              Container(
                padding: const EdgeInsets.symmetric(
                  vertical: 12,
                  horizontal: 24,
                ),
                decoration: BoxDecoration(
                  color:
                      widget.isRunning
                          ? AppColors.accent
                          : AppColors.accent.withValues(alpha: 0.3),
                  borderRadius: BorderRadius.circular(25),
                ),
                child: Text(
                  '${widget.elapsed.inMinutes.toString().padLeft(2, '0')}:${(widget.elapsed.inSeconds % 60).toString().padLeft(2, '0')}',
                  style: AppTextStyles.titleLarge.copyWith(
                    color: AppColors.primary,
                    fontWeight: FontWeight.bold,
                    fontSize: 24,
                  ),
                ),
              ),

              const SizedBox(height: 32),

              // Weight selector
              Center(
                child: WeightSelectorVelocity(
                  initialWeight: _selectedWeight,
                  onWeightChanged: (weight) {
                    setState(() => _selectedWeight = weight);
                  },
                ),
              ),

              const SizedBox(height: 24),

              // Sets table
              if (widget.completedSets.isNotEmpty) ...[
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: AppColors.accent.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: AppColors.accent.withValues(alpha: 0.3),
                    ),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Completed Sets',
                        style: AppTextStyles.titleSmall.copyWith(
                          color: AppColors.primary,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 12),
                      ...(widget.completedSets.map(
                        (set) => Padding(
                          padding: const EdgeInsets.symmetric(vertical: 4),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                'Set ${set.setNumber}',
                                style: AppTextStyles.bodyMedium.copyWith(
                                  color: AppColors.primary.withValues(
                                    alpha: 0.7,
                                  ),
                                ),
                              ),
                              Text(
                                '${set.reps} reps × ${set.weight}kg',
                                style: AppTextStyles.bodyMedium.copyWith(
                                  color: AppColors.primary,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                              Text(
                                '${set.time.inMinutes}:${(set.time.inSeconds % 60).toString().padLeft(2, '0')}',
                                style: AppTextStyles.bodySmall.copyWith(
                                  color: AppColors.primary.withValues(
                                    alpha: 0.5,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      )),
                    ],
                  ),
                ),
                const SizedBox(height: 24),
              ],

              const Spacer(),

              // Action buttons
              Center(
                child: SizedBox(
                  width: buttonWidth,
                  height: 56,
                  child: ElevatedButton(
                    onPressed: () => _showRepsSelector(context),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.accent,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: Text(
                      widget.finishType == FinishType.set
                          ? 'Finish Set'
                          : widget.finishType == FinishType.exercise
                          ? 'Finish Exercise'
                          : 'Finish Workout',
                      style: AppTextStyles.button.copyWith(
                        color: AppColors.primary,
                        fontSize: 18,
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 20),
            ],
          ),
        ),
      ),
    );
  }
}
