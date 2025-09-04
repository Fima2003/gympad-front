import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
// Migrated to bloc run-phase rest timer (removed local timer).
import '../../constants/app_styles.dart';
import '../../models/exercise.dart';
import '../../models/workout.dart';
import '../../models/workout_exercise.dart';
import '../../models/workout_set.dart';
import '../../blocs/workout/workout_bloc.dart';
import '../well_done_workout_screen.dart';
import '../../widgets/exercise_chip.dart';

class FreeWorkoutBreakScreen extends StatefulWidget {
  final Exercise currentExercise;
  final bool isPartOfWorkout;
  final VoidCallback onNewSet;
  final VoidCallback onNewExercise;
  final List<WorkoutSet> completedSets;

  const FreeWorkoutBreakScreen({
    super.key,
    required this.currentExercise,
    required this.isPartOfWorkout,
    required this.onNewSet,
    required this.onNewExercise,
    required this.completedSets,
  });

  @override
  State<FreeWorkoutBreakScreen> createState() => _FreeWorkoutBreakScreenState();
}

class _FreeWorkoutBreakScreenState extends State<FreeWorkoutBreakScreen> {
  bool _isFinishingWorkout = false;
  bool _autoPopOnNextSet = false; // only pop when user explicitly chose NEW SET

  @override
  void initState() {
    super.initState();
  }

  String _formatTime(int seconds) {
    final minutes = seconds ~/ 60;
    final remainingSeconds = seconds % 60;
    return '${minutes.toString().padLeft(2, '0')}:${remainingSeconds.toString().padLeft(2, '0')}';
  }

  void _finishWorkout() async {
    if (widget.isPartOfWorkout) {
      // In run-phase model: finish early only allowed during rest -> dispatch RunFinishEarly
      setState(() => _isFinishingWorkout = true);
      context.read<WorkoutBloc>().add(const RunFinishEarly());
      return; // Navigation handled by listener on WorkoutCompleted
    }

    if (mounted) {
      // Create a temporary workout for the well done screen
      final workoutExercise = WorkoutExercise(
        exerciseId: widget.currentExercise.id,
        name: widget.currentExercise.name,
        muscleGroup: widget.currentExercise.muscleGroup,
        sets: widget.completedSets,
        startTime: DateTime.now().subtract(
          Duration(minutes: 1),
        ), // Approximate start time
        endTime: DateTime.now(),
      );

      final tempWorkout = Workout(
        id:
            'temp_${widget.currentExercise.id}_${DateTime.now().millisecondsSinceEpoch}',
        name: widget.currentExercise.name,
        exercises: [workoutExercise],
        startTime: workoutExercise.startTime,
        endTime: workoutExercise.endTime,
        isOngoing: false,
      );

      Navigator.of(context).pushReplacement(
        MaterialPageRoute(
          builder: (context) => WellDoneWorkoutScreen(workout: tempWorkout),
        ),
      );
    }
  }

  void _showFinishDialog() {
    if (_isFinishingWorkout) return;
    showDialog(
      context: context,
      builder:
          (context) => AlertDialog(
            title: const Text('Finish workout?'),
            content: const Text(
              'Are you sure you want to finish this workout now?',
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(),
                child: const Text('No'),
              ),
              ElevatedButton(
                onPressed: () {
                  Navigator.of(context).pop();
                  _finishWorkout();
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.red,
                  foregroundColor: Colors.white,
                ),
                child: const Text('Yes'),
              ),
            ],
          ),
    );
  }

  @override
  void dispose() {
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return BlocListener<WorkoutBloc, WorkoutState>(
      listener: (context, state) {
        if (state is WorkoutRunInSet && widget.isPartOfWorkout) {
          if (_autoPopOnNextSet && Navigator.of(context).canPop()) {
            _autoPopOnNextSet = false; // reset
            Navigator.of(context).pop();
          }
        } else if (state is WorkoutCompleted && widget.isPartOfWorkout) {
          // Reset loading state and navigate to Well Done Workout screen
          setState(() {
            _isFinishingWorkout = false;
          });
          // Use pushAndRemoveUntil to clear the navigation stack and go to Well Done screen
          Navigator.of(context).pushAndRemoveUntil(
            MaterialPageRoute(
              builder:
                  (context) => WellDoneWorkoutScreen(workout: state.workout),
            ),
            (Route<dynamic> route) =>
                route
                    .isFirst, // Keep only the first route (usually the main screen)
          );
        } else if (state is WorkoutError) {
          // Reset loading state on error
          setState(() {
            _isFinishingWorkout = false;
          });
          // Show error message
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(state.message), backgroundColor: Colors.red),
          );
        }
      },
      child: Scaffold(
        backgroundColor: const Color(
          0xFF1a1a1a,
        ), // Darker background for better contrast
        body: SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Stack(
              children: [
                // Main content
                Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    // Rest title
                    Text(
                      'REST TIME',
                      style: AppTextStyles.titleLarge.copyWith(
                        color: Colors.white,
                        fontSize: 28,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 2,
                      ),
                      textAlign: TextAlign.center,
                    ),

                    const SizedBox(height: 40),

                    // Timer with circular progress background
                    BlocBuilder<WorkoutBloc, WorkoutState>(
                      builder: (context, st) {
                        if (st is! WorkoutRunRest) {
                          return const SizedBox(height: 200); // placeholder
                        }
                        final elapsed =
                            st.total.inSeconds - st.remaining.inSeconds;
                        return Stack(
                          alignment: Alignment.center,
                          children: [
                            SizedBox(
                              width: 200,
                              height: 200,
                              child: CircularProgressIndicator(
                                value: null,
                                strokeWidth: 8,
                                backgroundColor: Colors.white.withValues(
                                  alpha: 0.2,
                                ),
                                valueColor: AlwaysStoppedAnimation<Color>(
                                  AppColors.accent,
                                ),
                              ),
                            ),
                            Column(
                              children: [
                                Text(
                                  _formatTime(elapsed),
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 48,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                Text(
                                  'elapsed',
                                  style: AppTextStyles.bodyMedium.copyWith(
                                    color: Colors.white70,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        );
                      },
                    ),

                    const SizedBox(height: 50),

                    // Current exercise info
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.08),
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(
                          color: Colors.white.withValues(alpha: 0.1),
                        ),
                      ),
                      child: Column(
                        children: [
                          Text(
                            'CURRENT EXERCISE',
                            style: AppTextStyles.bodyMedium.copyWith(
                              color: Colors.white70,
                              fontWeight: FontWeight.w600,
                              letterSpacing: 1,
                            ),
                          ),
                          const SizedBox(height: 12),
                          Text(
                            widget.currentExercise.name.toUpperCase(),
                            style: AppTextStyles.titleMedium.copyWith(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                            ),
                            textAlign: TextAlign.center,
                          ),
                          const SizedBox(height: 8),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 6,
                            ),
                            decoration: BoxDecoration(
                              color: AppColors.accent.withValues(alpha: 0.2),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Text(
                              widget.currentExercise.muscleGroup.toUpperCase(),
                              style: AppTextStyles.bodySmall.copyWith(
                                color: AppColors.accent,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),

                    // Previous exercises (visual only) — show only in workout mode
                    if (widget.isPartOfWorkout) ...[
                      const SizedBox(height: 16),
                      BlocBuilder<WorkoutBloc, WorkoutState>(
                        builder: (context, st) {
                          Workout? w;
                          if (st is WorkoutRunRest)
                            w = st.workout;
                          else if (st is WorkoutRunInSet)
                            w = st.workout;
                          else if (st is WorkoutInProgress)
                            w = st.workout;
                          if (w == null) return const SizedBox.shrink();
                          final list = w.exercises;
                          if (list.length <= 1) return const SizedBox.shrink();
                          final previous = list.take(list.length - 1).toList();
                          return _PreviousExercisesRow(items: previous);
                        },
                      ),
                    ],

                    const SizedBox(height: 80),

                    // Action buttons
                    if (widget.isPartOfWorkout) ...[
                      // Buttons layout for workout (New Set / New Exercise) - finish moved to flag icon
                      Column(
                        children: [
                          SizedBox(
                            width: double.infinity,
                            height: 50,
                            child: ElevatedButton(
                              onPressed: () {
                                // Skip rest start next set and schedule auto pop.
                                _autoPopOnNextSet = true;
                                context.read<WorkoutBloc>().add(
                                  const RunSkipRest(),
                                );
                              },
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.white,
                                foregroundColor: const Color(0xFF1a1a1a),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                elevation: 4,
                              ),
                              child: Text(
                                'NEW SET',
                                style: AppTextStyles.button.copyWith(
                                  color: const Color(0xFF1a1a1a),
                                  fontWeight: FontWeight.bold,
                                  fontSize: 16,
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(height: 12),
                          SizedBox(
                            width: double.infinity,
                            height: 50,
                            child: OutlinedButton(
                              onPressed: () {
                                if (_isFinishingWorkout) return;
                                // Navigate to selection; do NOT set auto pop so current rest screen remains until user returns.
                                Navigator.of(context).pop();
                                widget.onNewExercise();
                              },
                              style: OutlinedButton.styleFrom(
                                foregroundColor: Colors.white,
                                side: const BorderSide(
                                  color: Colors.white,
                                  width: 2,
                                ),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(8),
                                ),
                              ),
                              child: Text(
                                'NEW EXERCISE',
                                style: AppTextStyles.button.copyWith(
                                  color: Colors.white,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 14,
                                ),
                                textAlign: TextAlign.center,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ] else ...[
                      // Two buttons layout for standalone exercise
                      Row(
                        children: [
                          Expanded(
                            child: SizedBox(
                              height: 56,
                              child: ElevatedButton(
                                onPressed: widget.onNewSet,
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: Colors.white,
                                  foregroundColor: const Color(0xFF1a1a1a),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  elevation: 4,
                                ),
                                child: Text(
                                  'START NEW SET',
                                  style: AppTextStyles.button.copyWith(
                                    color: const Color(0xFF1a1a1a),
                                    fontWeight: FontWeight.bold,
                                  ),
                                  textAlign: TextAlign.center,
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: SizedBox(
                              height: 56,
                              child: OutlinedButton(
                                onPressed:
                                    _isFinishingWorkout ? null : _finishWorkout,
                                style: OutlinedButton.styleFrom(
                                  foregroundColor: Colors.white,
                                  side: const BorderSide(
                                    color: Colors.white,
                                    width: 2,
                                  ),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                ),
                                child:
                                    _isFinishingWorkout
                                        ? SizedBox(
                                          height: 20,
                                          width: 20,
                                          child: CircularProgressIndicator(
                                            strokeWidth: 2,
                                            valueColor:
                                                AlwaysStoppedAnimation<Color>(
                                                  Colors.white,
                                                ),
                                          ),
                                        )
                                        : Text(
                                          'FINISH EXERCISE',
                                          style: AppTextStyles.button.copyWith(
                                            color: Colors.white,
                                            fontWeight: FontWeight.bold,
                                          ),
                                          textAlign: TextAlign.center,
                                        ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ],
                ),
                // Finish workout flag icon (only for workout mode)
                if (widget.isPartOfWorkout)
                  Positioned(
                    top: 0,
                    right: 0,
                    child:
                        _isFinishingWorkout
                            ? const SizedBox(
                              width: 32,
                              height: 32,
                              child: CircularProgressIndicator(
                                strokeWidth: 3,
                                valueColor: AlwaysStoppedAnimation<Color>(
                                  Colors.white,
                                ),
                              ),
                            )
                            : IconButton(
                              tooltip: 'Finish workout',
                              icon: const Icon(Icons.flag, color: Colors.white),
                              onPressed: _showFinishDialog,
                            ),
                  ),
              ],
            ),
          ),
        ),
      ),
    ); // Closing BlocListener
  }
}

class _PreviousExercisesRow extends StatelessWidget {
  final List<WorkoutExercise> items;
  const _PreviousExercisesRow({required this.items});

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children:
            items.map((e) {
              return ExerciseChip(
                title: e.name.replaceAll('_', ' ').toUpperCase(),
                setsCount: e.sets.length,
                variant: ExerciseChipVariant.previous,
                margin: const EdgeInsets.only(top: 8, right: 10),
              );
            }).toList(),
      ),
    );
  }
}
