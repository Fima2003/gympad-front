import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'dart:async';
import '../../constants/app_styles.dart';
import '../../models/predefined_workout.dart';
import '../../models/workout_set.dart';
import '../../blocs/workout_bloc.dart';
import '../../services/global_timer_service.dart';
import '../../widgets/weight_selector.dart';
import '../../widgets/reps_selector.dart';
import 'custom_workout_break_screen.dart';
import '../well_done_workout_screen.dart';
import '../../services/data_service.dart';

class PredefinedWorkoutsRunScreen extends StatefulWidget {
  final PredefinedWorkout workout;

  const PredefinedWorkoutsRunScreen({
    super.key,
    required this.workout,
  });

  @override
  State<PredefinedWorkoutsRunScreen> createState() => _PredefinedWorkoutsRunScreenState();
}

class _PredefinedWorkoutsRunScreenState extends State<PredefinedWorkoutsRunScreen> {
  int _currentExerciseIndex = 0;
  int _currentSetIndex = 0;
  double _selectedWeight = 0.0;
  int _selectedReps = 0;
  Timer? _setTimer;
  Duration _setDuration = Duration.zero;
  bool _isTimerRunning = false;
  List<WorkoutSet> _completedSets = [];
  bool _isFinishing = false;

  @override
  void initState() {
    super.initState();
    _initializeWorkout();
    _startSetTimer();
  }

  void _initializeWorkout() {
    // Start the workout through WorkoutBloc with the predefined workout name
    context.read<WorkoutBloc>().add(WorkoutStarted(name: widget.workout.name));
    GlobalTimerService().start();

    // Set initial weight and reps
  final firstExercise = widget.workout.exercises[_currentExerciseIndex];
  _selectedWeight = firstExercise.suggestedWeight ?? 0.0;
  _selectedReps = firstExercise.suggestedReps ?? 10;
  }

  void _startSetTimer() {
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

  PredefinedWorkoutExercise get _currentExercise =>
      widget.workout.exercises[_currentExerciseIndex];

  bool get _isLastSet => _currentSetIndex >= _currentExercise.setsAmount - 1;
  bool get _isLastExercise => _currentExerciseIndex >= widget.workout.exercises.length - 1;

  void _showRepsSelector() {
    _stopSetTimer(); // Stop timer when showing reps selector
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return RepsSelector(
          initialReps: _currentExercise.suggestedReps,
          onRepsSelected: (int reps) {
            setState(() {
              _selectedReps = reps;
            });
            _finishCurrentAction();
          },
        );
      },
    );
  }

  void _startSet() {
    _startSetTimer();
  }

  void _stopSet() {
    _showRepsSelector();
  }

  void _resetSetTimer() {
    _setTimer?.cancel();
    setState(() {
      _setDuration = Duration.zero;
      _isTimerRunning = false;
    });
  }

  void _finishCurrentAction() {
    // Create the set with actual time from timer
    final workoutSet = WorkoutSet(
      setNumber: _currentSetIndex + 1,
      reps: _selectedReps,
      weight: _selectedWeight,
      time: _setDuration,
    );

    // Add to local completed sets for UI purposes
    setState(() {
      _completedSets.add(workoutSet);
    });

    // If this is the first set of the exercise, add the exercise to the workout
    if (_currentSetIndex == 0) {
      final exerciseMeta = DataService().getExercise(_currentExercise.id);
      context.read<WorkoutBloc>().add(ExerciseAdded(
        exerciseId: _currentExercise.id,
        name: exerciseMeta?.name ?? _currentExercise.id,
        muscleGroup: exerciseMeta?.muscleGroup ??
            (widget.workout.muscleGroups.isNotEmpty ? widget.workout.muscleGroups.first : 'Unknown'),
      ));
    }

    // Add the set to the current exercise
    context.read<WorkoutBloc>().add(SetAdded(
      reps: _selectedReps,
      weight: _selectedWeight,
      duration: _setDuration,
    ));

    if (_isLastSet && _isLastExercise) {
      _finishWorkout();
    } else if (_isLastSet) {
      _moveToNextExercise();
    } else {
      _moveToNextSet();
    }
  }

  void _moveToNextSet() {
    _currentSetIndex++;
    _resetSetTimer();
    
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => PredefinedWorkoutBreakScreen(
          restTime: _currentExercise.restTime,
          nextExercise: _currentExercise,
          currentSetIndex: _currentSetIndex,
          totalSets: _currentExercise.setsAmount,
          workoutProgress: _calculateProgress(),
          onBreakComplete: () {
            Navigator.of(context).pop();
            // Automatically start timer for next set
            _startSetTimer();
          },
        ),
      ),
    );
  }

  void _moveToNextExercise() {
    // Finish the current exercise
    context.read<WorkoutBloc>().add(ExerciseFinished());
    
    _currentExerciseIndex++;
    _currentSetIndex = 0;
    _resetSetTimer();
    
    // Clear completed sets for new exercise
    setState(() {
      _completedSets = [];
    });
    
    // Update weight and reps for next exercise
  final nextExercise = widget.workout.exercises[_currentExerciseIndex];
    _selectedWeight = nextExercise.suggestedWeight ?? _selectedWeight;
    _selectedReps = nextExercise.suggestedReps ?? _selectedReps;

    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => PredefinedWorkoutBreakScreen(
          restTime: widget.workout.exercises[_currentExerciseIndex - 1].restTime,
          nextExercise: nextExercise,
          currentSetIndex: _currentSetIndex,
          totalSets: nextExercise.setsAmount,
          workoutProgress: _calculateProgress(),
          onBreakComplete: () {
            Navigator.of(context).pop();
            // Automatically start timer for next exercise
            _startSetTimer();
          },
        ),
      ),
    );
  }

  void _finishWorkout() {
    if (_isFinishing) return; // prevent duplicate triggers
    setState(() {
      _isFinishing = true;
    });
    // Finish the current exercise if there is one
    context.read<WorkoutBloc>().add(ExerciseFinished());
    
    // Finish the workout
    context.read<WorkoutBloc>().add(WorkoutFinished());
    
    GlobalTimerService().stop();
  }

  double _calculateProgress() {
    int totalExercises = widget.workout.exercises.length;
    int totalSetsCompleted = 0;
    int totalSets = 0;

    for (int i = 0; i < totalExercises; i++) {
      int exerciseSets = widget.workout.exercises[i].setsAmount;
      totalSets += exerciseSets;
      
      if (i < _currentExerciseIndex) {
        totalSetsCompleted += exerciseSets;
      } else if (i == _currentExerciseIndex) {
        totalSetsCompleted += _currentSetIndex;
      }
    }

    return totalSetsCompleted / totalSets;
  }

  void _showExitDialog() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Exit Workout'),
          content: const Text('Are you sure you want to quit this workout?'),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('No'),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.of(context).pop(); // Close dialog
                _finishWorkout();
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red,
                foregroundColor: Colors.white,
              ),
              child: const Text('Yes'),
            ),
          ],
        );
      },
    );
  }

  @override
  void dispose() {
    _setTimer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    const double buttonWidth = 280.0;
    
  return BlocListener<WorkoutBloc, WorkoutState>(
      listener: (context, state) {
        if (state is WorkoutCompleted) {
          Navigator.of(context).pushReplacement(
            MaterialPageRoute(
              builder: (context) => WellDoneWorkoutScreen(
                workout: state.workout,
              ),
            ),
          );
        } else if (state is WorkoutError) {
          if (mounted) {
            setState(() {
              _isFinishing = false; // allow retry if something went wrong
            });
          }
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(state.message),
              backgroundColor: Colors.red,
            ),
          );
        }
      },
      child: Stack(
        children: [
          Scaffold(
            backgroundColor: AppColors.background,
            appBar: AppBar(
              backgroundColor: AppColors.background,
              elevation: 0,
              automaticallyImplyLeading: false,
              title: Text(
                widget.workout.name,
                style: AppTextStyles.titleMedium.copyWith(
                  color: AppColors.primary,
                  fontWeight: FontWeight.bold,
                ),
              ),
              actions: [
                IconButton(
                  onPressed: _isFinishing ? null : _showExitDialog,
                  icon: Icon(Icons.close, color: AppColors.primary),
                ),
              ],
            ),
            body: SafeArea(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Column(
            children: [
              // Exercise name
              Text(
                (DataService().getExercise(_currentExercise.id)?.name ?? _currentExercise.id)
                    .replaceAll('_', ' ')
                    .toUpperCase(),
                style: AppTextStyles.titleLarge.copyWith(
                  color: AppColors.primary,
                  fontWeight: FontWeight.bold,
                ),
                textAlign: TextAlign.center,
              ),
              
              const SizedBox(height: 8),
              
              // Set info
              Text(
                'Set ${_currentSetIndex + 1} of ${_currentExercise.setsAmount}',
                style: AppTextStyles.bodyLarge.copyWith(
                  color: AppColors.primary.withValues(alpha: 0.7),
                ),
              ),
              
              const SizedBox(height: 24),
              
              // Timer display
              Container(
                padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 24),
                decoration: BoxDecoration(
                  color: _isTimerRunning ? AppColors.accent : AppColors.accent.withValues(alpha: 0.3),
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
              
              // Weight selector
              Center(
                child: WeightSelector(
                  initialWeight: _selectedWeight,
                  onWeightChanged: (weight) {
                    setState(() {
                      _selectedWeight = weight;
                    });
                  },
                ),
              ),
              
              const SizedBox(height: 24),
              
              // Sets table
              if (_completedSets.isNotEmpty) ...[
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: AppColors.accent.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: AppColors.accent.withValues(alpha: 0.3)),
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
                      ...(_completedSets.map((set) => Padding(
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
                      ))),
                    ],
                  ),
                ),
                const SizedBox(height: 24),
              ],
              
              const Spacer(),
              
              // Action buttons
              if (_isTimerRunning) ...[
                // During set - Stop Set button
                Center(
                  child: SizedBox(
                    width: buttonWidth,
                    height: 56,
                    child: ElevatedButton(
                      onPressed: _isFinishing ? null : _stopSet,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.accent,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: Text(
                        'Stop Set',
                        style: AppTextStyles.button.copyWith(
                          color: AppColors.primary,
                          fontSize: 18,
                        ),
                      ),
                    ),
                  ),
                ),
              ] else if (_completedSets.isEmpty) ...[
                // This should never happen since we auto-start timer
                // But keeping as fallback
                Center(
                  child: SizedBox(
                    width: buttonWidth,
                    height: 56,
                    child: ElevatedButton(
                      onPressed: _isFinishing ? null : _startSet,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primary,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: Text(
                        'Start Set',
                        style: AppTextStyles.button.copyWith(
                          color: AppColors.white,
                          fontSize: 18,
                        ),
                      ),
                    ),
                  ),
                ),
              ] else ...[
                // Between sets - New Set button or finish buttons
                if (!_isLastSet) ...[
                  Center(
                    child: SizedBox(
                      width: buttonWidth,
                      height: 56,
                      child: ElevatedButton(
                        onPressed: _isFinishing ? null : _startSet,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.primary,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        child: Text(
                          'New Set',
                          style: AppTextStyles.button.copyWith(
                            color: AppColors.white,
                            fontSize: 18,
                          ),
                        ),
                      ),
                    ),
                  ),
                ] else ...[
                  // Last set - show finish buttons
                  Center(
                    child: SizedBox(
                      width: buttonWidth,
                      child: _isLastExercise 
                        ? SizedBox(
                            width: double.infinity,
                            height: 56,
                            child: ElevatedButton(
                              onPressed: _isFinishing ? null : _finishWorkout,
                              style: ElevatedButton.styleFrom(
                                backgroundColor: AppColors.primary,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                              ),
                              child: Text(
                                'Finish Workout',
                                style: AppTextStyles.button.copyWith(
                                  color: AppColors.white,
                                  fontSize: 18,
                                ),
                              ),
                            ),
                          )
                        : SizedBox(
                            width: double.infinity,
                            height: 56,
                            child: ElevatedButton(
                              onPressed: _isFinishing ? null : () => _showRepsSelector(),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: AppColors.accent,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                              ),
                              child: Text(
                                'Next Exercise',
                                style: AppTextStyles.button.copyWith(
                                  color: AppColors.primary,
                                  fontSize: 18,
                                ),
                              ),
                            ),
                          ),
                    ),
                  ),
                ],
              ],
              
              const SizedBox(height: 20),
            ],
                ),
              ),
            ),
          ),
          if (_isFinishing) ...[
            const ModalBarrier(dismissible: false, color: Colors.black26),
            Center(
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                decoration: BoxDecoration(
                  color: AppColors.background,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: AppColors.accent.withValues(alpha: 0.4)),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.1),
                      blurRadius: 8,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    SizedBox(
                      width: 22,
                      height: 22,
                      child: CircularProgressIndicator(
                        strokeWidth: 3,
                        valueColor: AlwaysStoppedAnimation<Color>(AppColors.primary),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Text(
                      'Finishing workout…',
                      style: AppTextStyles.bodyMedium.copyWith(
                        color: AppColors.primary,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ],
      ));
  }
}
