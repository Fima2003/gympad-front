import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../constants/app_styles.dart';
import '../../models/gym.dart';
import '../../models/exercise.dart';
import '../../models/workout_set.dart';
import '../../blocs/workout/workout_bloc.dart';
import '../../services/workout_service.dart';
import '../../widgets/velocity_weight_selector.dart';
import 'dart:async';
import '../../widgets/reps_selector.dart';
import 'select_exercise_screen.dart';
import 'free_workout_break_screen.dart';

class ExerciseScreen extends StatefulWidget {
  final Gym? gym;
  final Exercise exercise;
  final bool isPartOfWorkout;

  const ExerciseScreen({
    super.key,
    this.gym,
    required this.exercise,
    this.isPartOfWorkout = false,
  });

  @override
  State<ExerciseScreen> createState() => _ExerciseScreenState();
}

class _ExerciseScreenState extends State<ExerciseScreen> {
  bool _isTimerRunning = false;
  double _selectedWeight = 15.0;
  Duration _setDuration = Duration.zero;
  Timer? _setTimer;
  List<WorkoutSet> _completedSets = [];
  bool _hasCompletedSets = false;
  bool _isAwaitingReps = false;

  @override
  void initState() {
    super.initState();
    // If this exercise exists in the current workout, preload its sets
    final state = context.read<WorkoutBloc>().state;
    if (state is WorkoutInProgress) {
      final existing =
          state.workout.exercises
              .where((e) => e.exerciseId == widget.exercise.id)
              .toList();
      if (existing.isNotEmpty) {
        _completedSets = List<WorkoutSet>.from(existing.last.sets);
        _hasCompletedSets = _completedSets.isNotEmpty;
      }
    }
  }

  void _startSet() {
    // Create workout and add exercise only when starting the first set
    if (widget.isPartOfWorkout && !_hasCompletedSets) {
      // Start global timer if not already started
      if (BlocProvider.of<WorkoutBloc>(context).state is! WorkoutInProgress) {
        BlocProvider.of<WorkoutBloc>(
          context,
        ).add(WorkoutStarted(WorkoutType.free));
      }

      // Add exercise to workout
      BlocProvider.of<WorkoutBloc>(context).add(
        ExerciseAdded(
          exerciseId: widget.exercise.id,
          name: widget.exercise.name,
          muscleGroup: widget.exercise.muscleGroup,
        ),
      );
    }

    _startSetTimer(reset: true);
  }

  void _stopSet() {
    _showRepsSelector();
  }

  void _showRepsSelector() {
    // Pause timer while selecting reps
    _stopSetTimer();
    setState(() {
      _isAwaitingReps = true;
    });

    showDialog<int>(
      context: context,
      barrierDismissible: true, // allow tapping outside to go back
      builder: (context) => const RepsSelector(),
    ).then((reps) {
      // If user tapped outside or pressed back, reps will be null -> resume timer
      if (!mounted) return;
      if (reps == null) {
        setState(() {
          _isAwaitingReps = false;
        });
        _startSetTimer(reset: false);
      } else {
        _saveSet(reps);
      }
    });
  }

  void _saveSet(int reps) {
    final setDuration = _setDuration;

    final newSet = WorkoutSet(
      setNumber: _completedSets.length + 1,
      reps: reps,
      weight: _selectedWeight,
      time: setDuration,
    );

    setState(() {
      _completedSets.add(newSet);
      _hasCompletedSets = true;
      _isAwaitingReps = false;
    });

    // If part of workout, add set to the workout
    if (widget.isPartOfWorkout) {
      context.read<WorkoutBloc>().add(
        SetAdded(reps: reps, weight: _selectedWeight, duration: setDuration),
      );
    }

    // Reset timer for next set
    _resetSetTimer();

    // Navigate to break screen
    Navigator.of(context).push(
      MaterialPageRoute(
        builder:
            (context) => FreeWorkoutBreakScreen(
              currentExercise: widget.exercise,
              isPartOfWorkout: widget.isPartOfWorkout,
              completedSets: _completedSets,
              onNewSet: () {
                Navigator.of(context).pop(); // Return to exercise screen
                _startNewSet();
              },
              onNewExercise: () {
                Navigator.of(context).pop(); // Return to exercise screen
                _newExercise();
              },
            ),
      ),
    );
  }

  void _startNewSet() {
    _startSetTimer(reset: true);
  }

  void _newExercise() {
    // Finish current exercise in workout
    if (widget.isPartOfWorkout) {
      // TODO add parameters to exercise finished
      // context.read<WorkoutBloc>().add(ExerciseFinished());
    }

    // Navigate to exercise selection, defaulting to current muscle group
    Navigator.of(context).push(
      MaterialPageRoute(
        builder:
            (context) => SelectExerciseScreen(
              selectedMuscleGroup: widget.exercise.muscleGroup,
            ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    const double buttonWidth = 280.0;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.background,
        elevation: 0,
        automaticallyImplyLeading: !_isTimerRunning,
        leading:
            _isTimerRunning
                ? null
                : IconButton(
                  icon: Icon(Icons.arrow_back, color: AppColors.primary),
                  onPressed: () => Navigator.of(context).pop(),
                ),
        title: Row(
          children: [
            Container(
              width: 32,
              height: 32,
              decoration: BoxDecoration(
                color: AppColors.primary,
                borderRadius: BorderRadius.circular(6),
              ),
              child: Icon(
                Icons.fitness_center,
                color: AppColors.white,
                size: 18,
              ),
            ),
            const SizedBox(width: 12),
            Text(
              widget.gym?.name ?? 'Workout',
              style: AppTextStyles.appBarTitle,
            ),
          ],
        ),
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: Column(
            children: [
              // Exercise name
              Text(
                widget.exercise.name.replaceAll('_', ' ').toUpperCase(),
                style: AppTextStyles.titleLarge.copyWith(
                  color: AppColors.primary,
                  fontWeight: FontWeight.bold,
                ),
                textAlign: TextAlign.center,
              ),

              const SizedBox(height: 8),

              // Set info (no total in free mode)
              Text(
                'Set ${_completedSets.length + ((_isTimerRunning || _isAwaitingReps) ? 1 : 0)}',
                style: AppTextStyles.bodyLarge.copyWith(
                  color: AppColors.primary.withValues(alpha: 0.7),
                ),
              ),

              const SizedBox(height: 24),

              // Timer display (pill)
              Container(
                padding: const EdgeInsets.symmetric(
                  vertical: 12,
                  horizontal: 24,
                ),
                decoration: BoxDecoration(
                  color:
                      _isTimerRunning
                          ? AppColors.accent
                          : AppColors.accent.withValues(alpha: 0.3),
                  borderRadius: BorderRadius.circular(25),
                ),
                child: Text(
                  '${_setDuration.inMinutes.toString().padLeft(2, '0')}:${(_setDuration.inSeconds % 60).toString().padLeft(2, '0')}',
                  style: AppTextStyles.titleLarge.copyWith(
                    color: AppColors.primary,
                    fontWeight: FontWeight.bold,
                    fontSize: 24,
                  ),
                ),
              ),

              const SizedBox(height: 32),

              // Weight selector (velocity-aware, 0.5kg steps)
              Center(
                child: WeightSelectorVelocity(
                  initialWeight: _selectedWeight,
                  onWeightChanged: (weight) {
                    setState(() {
                      _selectedWeight = weight;
                    });
                  },
                ),
              ),

              const SizedBox(height: 24),

              // Completed sets list (styled similar to custom)
              if (_completedSets.isNotEmpty) ...[
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
                      ...(_completedSets.map(
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

              // Action button
              Center(
                child: SizedBox(
                  width: buttonWidth,
                  height: 56,
                  child: ElevatedButton(
                    onPressed: _isTimerRunning ? _stopSet : _startSet,
                    style: ElevatedButton.styleFrom(
                      backgroundColor:
                          _isTimerRunning
                              ? AppColors.accent
                              : AppColors.primary,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: Text(
                      _isTimerRunning ? 'Stop Set' : 'Start Set',
                      style: AppTextStyles.button.copyWith(
                        color:
                            _isTimerRunning
                                ? AppColors.primary
                                : AppColors.white,
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
    ); // Close Scaffold
  }

  void _startSetTimer({bool reset = false}) {
    _setTimer?.cancel();
    if (reset) {
      _setDuration = Duration.zero;
    }
    _setTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      setState(() {
        _setDuration = Duration(seconds: _setDuration.inSeconds + 1);
      });
    });
    setState(() {
      _isTimerRunning = true;
    });
  }

  void _stopSetTimer() {
    _setTimer?.cancel();
    setState(() {
      _isTimerRunning = false;
    });
  }

  void _resetSetTimer() {
    _setTimer?.cancel();
    setState(() {
      _setDuration = Duration.zero;
      _isTimerRunning = false;
    });
  }

  @override
  void dispose() {
    _setTimer?.cancel();
    super.dispose();
  }
}
