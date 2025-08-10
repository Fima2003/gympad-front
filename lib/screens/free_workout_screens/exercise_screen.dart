import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../constants/app_styles.dart';
import '../../models/gym.dart';
import '../../models/exercise.dart';
import '../../models/workout_set.dart';
import '../../services/global_timer_service.dart';
import '../../blocs/workout_bloc.dart';
import '../../widgets/weight_selector.dart';
import '../../widgets/workout_timer.dart';
import '../../widgets/workout_sets_table.dart';
import '../../widgets/reps_selector.dart';
import 'select_exercise_screen.dart';
import 'free_workout_break_screen.dart';

class ExerciseScreen extends StatefulWidget {
  final Gym? gym;
  final Exercise exercise;
  final bool isPartOfWorkout;

  const ExerciseScreen({
    Key? key, 
    this.gym, 
    required this.exercise,
    this.isPartOfWorkout = false,
  }) : super(key: key);

  @override
  State<ExerciseScreen> createState() => _ExerciseScreenState();
}

class _ExerciseScreenState extends State<ExerciseScreen> {
  final GlobalKey<WorkoutTimerState> _timerKey = GlobalKey();
  final GlobalTimerService _globalTimerService = GlobalTimerService();

  bool _isTimerRunning = false;
  double _selectedWeight = 15.0;
  Duration _currentSetTime = Duration.zero;
  List<WorkoutSet> _completedSets = [];
  bool _hasCompletedSets = false;
  DateTime? _setStartTime;

  void _startSet() {
    // Create workout and add exercise only when starting the first set
    if (widget.isPartOfWorkout && !_hasCompletedSets) {
      // Start global timer if not already started
      if (!_globalTimerService.isRunning) {
        context.read<WorkoutBloc>().add(WorkoutStarted());
        _globalTimerService.start();
      }
      
      // Add exercise to workout
      context.read<WorkoutBloc>().add(ExerciseAdded(
        exerciseId: widget.exercise.id,
        name: widget.exercise.name,
        muscleGroup: widget.exercise.muscleGroup,
      ));
    }
    
    _setStartTime = DateTime.now();
    setState(() {
      _isTimerRunning = true;
    });
  }

  void _stopSet() {
    setState(() {
      _isTimerRunning = false;
    });
    _showRepsSelector();
  }

  void _showRepsSelector() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder:
          (context) => RepsSelector(
            onRepsSelected: (reps) {
              _saveSet(reps);
            },
          ),
    );
  }

  void _saveSet(int reps) {
    final setDuration = _setStartTime != null 
        ? DateTime.now().difference(_setStartTime!)
        : _currentSetTime;
    
    final newSet = WorkoutSet(
      setNumber: _completedSets.length + 1,
      reps: reps,
      weight: _selectedWeight,
      time: setDuration,
    );

    setState(() {
      _completedSets.add(newSet);
      _hasCompletedSets = true;
    });

    // If part of workout, add set to the workout
    if (widget.isPartOfWorkout) {
      context.read<WorkoutBloc>().add(SetAdded(
        reps: reps,
        weight: _selectedWeight,
        duration: setDuration,
      ));
    }

    // Reset timer for next set
    _timerKey.currentState?.reset();
    
    // Navigate to break screen
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => FreeWorkoutBreakScreen(
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
    _setStartTime = DateTime.now();
    setState(() {
      _isTimerRunning = true;
    });
  }

  void _newExercise() {
    // Finish current exercise in workout
    if (widget.isPartOfWorkout) {
      context.read<WorkoutBloc>().add(ExerciseFinished());
    }
    
    // Navigate to exercise selection, defaulting to current muscle group
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => SelectExerciseScreen(
          selectedMuscleGroup: widget.exercise.muscleGroup,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    // Calculate button container width matching WeightSelector
    final screenWidth = MediaQuery.of(context).size.width;
    final int weightSelectorItemCount =
        ((screenWidth / 80).floor() ~/ 2) * 2 + 1;
    final double buttonWidth = weightSelectorItemCount * 65.0;

    return Scaffold(
        backgroundColor: AppColors.background,
        appBar: AppBar(
          backgroundColor: AppColors.background,
          elevation: 0,
          automaticallyImplyLeading: !_isTimerRunning,
          leading: _isTimerRunning ? null : IconButton(
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
            Text(widget.gym?.name ?? 'Workout', style: AppTextStyles.appBarTitle),
          ],
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Exercise title
            Text(widget.exercise.name, style: AppTextStyles.titleLarge),
            const SizedBox(height: 32),

            // Timer
            Center(
              child: WorkoutTimer(
                key: _timerKey,
                isRunning: _isTimerRunning,
                onTimeChanged: (time) {
                  _currentSetTime = time;
                },
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
            const SizedBox(height: 32),

            // Action buttons - simplified to only Start/Stop Set
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
                    alignment: Alignment.center,
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
            const SizedBox(height: 32),

            // Workout sets table
            WorkoutSetsTable(sets: _completedSets),
          ], // Close Column children
        ), // Close Column
      ), // Close SingleChildScrollView
    ); // Close Scaffold
  }
}
