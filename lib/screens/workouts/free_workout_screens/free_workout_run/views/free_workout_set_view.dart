import 'package:flutter/material.dart';

import '../../../../../constants/app_styles.dart';
import '../../../../../models/workout_set.dart';
import '../../../../../widgets/reps_selector.dart';
import '../../../../../widgets/velocity_weight_selector.dart';

/// Free workout set-running view (standalone, not yet wired into navigation).
/// Mirrors the structure of `CWorkoutRunView` but adapted for the open-ended
/// nature of free workouts (no predetermined total sets or finishType changes).
///
/// Responsibilities:
/// - Display current exercise name.
/// - Show incremental set number (completed + 1 while running).
/// - Show per-set elapsed timer (passed in from parent / bloc state).
/// - Allow weight adjustment (local state only until set finished).
/// - List completed sets beneath.
/// - Trigger reps selection dialog and invoke [onFinish] callback.
class FreeWorkoutSetView extends StatefulWidget {
  final String exerciseName;
  final List<WorkoutSet> completedSets;
  final Duration elapsed; // elapsed time for the active (current) set
  final double initialWeight;
  final int? suggestedReps; // optional (free mode may not have suggestion)
  final bool isRunning; // whether timer is active (from bloc)
  final void Function(double weight, int reps, Duration duration) onFinish;

  const FreeWorkoutSetView({
    super.key,
    required this.exerciseName,
    required this.completedSets,
    required this.elapsed,
    required this.initialWeight,
    required this.isRunning,
    required this.onFinish,
    this.suggestedReps,
  });

  @override
  State<FreeWorkoutSetView> createState() => _FreeWorkoutSetViewState();
}

class _FreeWorkoutSetViewState extends State<FreeWorkoutSetView> {
  late double _selectedWeight;

  @override
  void initState() {
    super.initState();
    _selectedWeight = widget.initialWeight;
  }

  @override
  void didUpdateWidget(covariant FreeWorkoutSetView oldWidget) {
    super.didUpdateWidget(oldWidget);
    // If exercise name changes (new exercise focused), reset weight baseline.
    if (oldWidget.exerciseName != widget.exerciseName) {
      _selectedWeight = widget.initialWeight;
    }
  }

  void _finishCurrentSet() {
    showDialog<int>(
      context: context,
      barrierDismissible: true,
      builder: (ctx) => RepsSelector(initialReps: widget.suggestedReps),
    ).then((reps) {
      if (reps == null) return; // user cancelled
      widget.onFinish(_selectedWeight, reps, widget.elapsed);
    });
  }

  @override
  Widget build(BuildContext context) {
    const double buttonWidth = 280.0;
    final currentSetNumber = widget.completedSets.length + 1; // next set idx +1

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.background,
        elevation: 0,
        automaticallyImplyLeading: false,
        title: Text(
          'Free Workout',
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
                widget.exerciseName.replaceAll('_', ' ').toUpperCase(),
                style: AppTextStyles.titleLarge.copyWith(
                  color: AppColors.primary,
                  fontWeight: FontWeight.bold,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 8),
              // Set info (open ended)
              Text(
                'Set $currentSetNumber',
                style: AppTextStyles.bodyLarge.copyWith(
                  color: AppColors.primary.withValues(alpha: 0.7),
                ),
              ),
              const SizedBox(height: 24),
              // Timer pill
              Container(
                padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 24),
                decoration: BoxDecoration(
                  color: widget.isRunning
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
                  onWeightChanged: (w) => setState(() => _selectedWeight = w),
                ),
              ),
              const SizedBox(height: 24),
              if (widget.completedSets.isNotEmpty)
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
                      ...widget.completedSets.map((set) => Padding(
                            padding: const EdgeInsets.symmetric(vertical: 4),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(
                                  'Set ${set.setNumber}',
                                  style: AppTextStyles.bodyMedium.copyWith(
                                    color: AppColors.primary.withValues(alpha: 0.7),
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
                                    color: AppColors.primary.withValues(alpha: 0.5),
                                  ),
                                ),
                              ],
                            ),
                          )),
                    ],
                  ),
                ),
              const Spacer(),
              Center(
                child: SizedBox(
                  width: buttonWidth,
                  height: 56,
                  child: ElevatedButton(
                    onPressed: _finishCurrentSet,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.accent,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: Text(
                      'Finish Set',
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
