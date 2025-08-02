import 'package:flutter/material.dart';
import '../constants/app_styles.dart';
import '../models/gym.dart';
import '../models/exercise.dart';
import '../models/workout_set.dart';
import '../services/storage_service.dart';
import '../widgets/weight_selector.dart';
import '../widgets/workout_timer.dart';
import '../widgets/workout_sets_table.dart';
import '../widgets/reps_selector.dart';
import 'well_done_screen.dart';

class ExerciseScreen extends StatefulWidget {
  final Gym gym;
  final Exercise exercise;

  const ExerciseScreen({Key? key, required this.gym, required this.exercise})
    : super(key: key);

  @override
  State<ExerciseScreen> createState() => _ExerciseScreenState();
}

class _ExerciseScreenState extends State<ExerciseScreen> {
  final GlobalKey<WorkoutTimerState> _timerKey = GlobalKey();
  final StorageService _storageService = StorageService();

  bool _isTimerRunning = false;
  double _selectedWeight = 15.0;
  Duration _currentSetTime = Duration.zero;
  List<WorkoutSet> _completedSets = [];
  bool _hasCompletedSets = false;

  void _startSet() {
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
    final newSet = WorkoutSet(
      setNumber: _completedSets.length + 1,
      reps: reps,
      weight: _selectedWeight,
      time: _currentSetTime,
    );

    setState(() {
      _completedSets.add(newSet);
      _hasCompletedSets = true;
    });

    // Reset timer for next set
    _timerKey.currentState?.reset();
  }

  void _startNewSet() {
    setState(() {
      _isTimerRunning = true;
    });
  }

  void _finishExercise() async {
    // Save to local storage
    await _storageService.saveWorkoutSets(widget.exercise.id, _completedSets);

    // Navigate to Well Done screen
    if (mounted) {
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(
          builder:
              (context) => WellDoneScreen(
                exercise: widget.exercise,
                completedSets: _completedSets,
              ),
        ),
      );
    }
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
        leading: IconButton(
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
            Text(widget.gym.name, style: AppTextStyles.appBarTitle),
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

            // Action buttons
            if (!_hasCompletedSets) ...[
              // Initial state - Start Set button
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
            ] else ...[
              // After completing sets - show different buttons based on timer state
              if (_isTimerRunning) ...[
                // During active set - only show Stop Set button
                Center(
                  child: SizedBox(
                    width: buttonWidth,
                    height: 56,
                    child: ElevatedButton(
                      onPressed: _stopSet,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.accent,
                        alignment: Alignment.center,
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
              ] else ...[
                // Between sets - show both buttons
                Center(
                  child: SizedBox(
                    width: buttonWidth,
                    child: Row(
                      children: [
                        Expanded(
                          child: SizedBox(
                            height: 56,
                            child: ElevatedButton(
                              onPressed: _startNewSet,
                              style: ElevatedButton.styleFrom(
                                backgroundColor: AppColors.primary,
                                alignment: Alignment.center,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                              ),
                              child: Text(
                                'Start New Set',
                                style: AppTextStyles.button.copyWith(
                                  color: AppColors.white,
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
                            child: ElevatedButton(
                              onPressed: _finishExercise,
                              style: ElevatedButton.styleFrom(
                                backgroundColor: AppColors.background,
                                alignment: Alignment.center,
                                side: BorderSide(
                                  color: AppColors.primary,
                                  width: 2,
                                ),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                              ),
                              child: Text(
                                'Finish Exercise',
                                style: AppTextStyles.button,
                                textAlign: TextAlign.center,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ],

            // Workout sets table
            WorkoutSetsTable(sets: _completedSets),
          ],
        ),
      ),
    );
  }
}
