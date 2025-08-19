import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'dart:async';
import '../../constants/app_styles.dart';
import '../../services/api/models/workout_models.dart';
import '../../models/workout_set.dart';
import '../../blocs/workout_bloc.dart';
import '../../services/global_timer_service.dart';
import '../../services/workout_service.dart';
import '../../widgets/weight_selector.dart';
import '../../widgets/reps_selector.dart';
// Using a lightweight inline break view for personal workouts
import '../well_done_workout_screen.dart';
import '../../services/data_service.dart';

class PersonalWorkoutsRunScreen extends StatefulWidget {
  final PersonalWorkoutResponse workout;

  const PersonalWorkoutsRunScreen({super.key, required this.workout});

  @override
  State<PersonalWorkoutsRunScreen> createState() => _PersonalWorkoutsRunScreenState();
}

class _PersonalWorkoutsRunScreenState extends State<PersonalWorkoutsRunScreen> {
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
    context.read<WorkoutBloc>().add(WorkoutStarted(WorkoutType.personal, name: widget.workout.name));
    GlobalTimerService().start();

    final first = widget.workout.exercises[_currentExerciseIndex];
    _selectedWeight = first.weight;
    _selectedReps = first.reps;
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

  PersonalWorkoutExerciseDto get _currentExercise => widget.workout.exercises[_currentExerciseIndex];

  bool get _isLastSet => _currentSetIndex >= _currentExercise.sets - 1;
  bool get _isLastExercise => _currentExerciseIndex >= widget.workout.exercises.length - 1;

  void _showRepsSelector() {
    _stopSetTimer();
    showDialog<int>(
      context: context,
      barrierDismissible: true,
      builder: (BuildContext context) {
        return RepsSelector(initialReps: _currentExercise.reps);
      },
    ).then((reps) {
      if (!mounted) return;
      if (reps == null) {
        _startSetTimer();
        return;
      }
      setState(() {
        _selectedReps = reps;
      });
      _finishCurrentAction();
    });
  }

  void _startSet() => _startSetTimer();
  void _stopSet() => _showRepsSelector();

  void _resetSetTimer() {
    _setTimer?.cancel();
    setState(() {
      _setDuration = Duration.zero;
      _isTimerRunning = false;
    });
  }

  void _finishCurrentAction() {
    final workoutSet = WorkoutSet(
      setNumber: _currentSetIndex + 1,
      reps: _selectedReps,
      weight: _selectedWeight,
      time: _setDuration,
    );

    setState(() {
      _completedSets.add(workoutSet);
    });

    if (_currentSetIndex == 0) {
      final exerciseMeta = DataService().getExercise(_currentExercise.exerciseId);
      context.read<WorkoutBloc>().add(
        ExerciseAdded(
          exerciseId: _currentExercise.exerciseId,
          name: exerciseMeta?.name ?? _currentExercise.name,
          muscleGroup: exerciseMeta?.muscleGroup ?? 'Unknown',
        ),
      );
    }

    context.read<WorkoutBloc>().add(
      SetAdded(reps: _selectedReps, weight: _selectedWeight, duration: _setDuration),
    );

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
        builder: (context) => _PersonalBreakOverlay(
          title: 'REST',
          onDone: () {
            Navigator.of(context).pop();
            _startSetTimer();
          },
        ),
      ),
    );
  }

  void _moveToNextExercise() {
    context.read<WorkoutBloc>().add(ExerciseFinished());

    _currentExerciseIndex++;
    _currentSetIndex = 0;
    _resetSetTimer();

    setState(() {
      _completedSets = [];
    });

    final next = widget.workout.exercises[_currentExerciseIndex];
    _selectedWeight = next.weight;
    _selectedReps = next.reps;

    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => _PersonalBreakOverlay(
          title: 'BREAK',
          onDone: () {
            Navigator.of(context).pop();
            _startSetTimer();
          },
        ),
      ),
    );
  }

  void _finishWorkout() {
    if (_isFinishing) return;
    setState(() => _isFinishing = true);
    context.read<WorkoutBloc>().add(ExerciseFinished());
    context.read<WorkoutBloc>().add(WorkoutFinished());
    GlobalTimerService().stop();
  }

  // Progress calc not used in this simplified flow

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
              builder: (context) => WellDoneWorkoutScreen(workout: state.workout),
            ),
          );
        } else if (state is WorkoutError) {
          if (mounted) {
            setState(() {
              _isFinishing = false;
            });
          }
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(state.message), backgroundColor: Colors.red),
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
            ),
            body: SafeArea(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Column(
                  children: [
                    Text(
                      (DataService().getExercise(_currentExercise.exerciseId)?.name ?? _currentExercise.name)
                          .replaceAll('_', ' ')
                          .toUpperCase(),
                      style: AppTextStyles.titleLarge.copyWith(
                        color: AppColors.primary,
                        fontWeight: FontWeight.bold,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Set ${_currentSetIndex + 1} of ${_currentExercise.sets}',
                      style: AppTextStyles.bodyLarge.copyWith(
                        color: AppColors.primary.withValues(alpha: 0.7),
                      ),
                    ),
                    const SizedBox(height: 24),
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
                    Center(
                      child: WeightSelector(
                        initialWeight: _selectedWeight,
                        onWeightChanged: (weight) {
                          setState(() => _selectedWeight = weight);
                        },
                      ),
                    ),
                    const SizedBox(height: 24),
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
                            Text('Completed Sets', style: AppTextStyles.titleSmall.copyWith(color: AppColors.primary, fontWeight: FontWeight.bold)),
                            const SizedBox(height: 8),
                            ..._completedSets.map((s) => Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                  children: [
                                    Text('Set ${s.setNumber}', style: AppTextStyles.bodySmall.copyWith(color: AppColors.primary)),
                                    Text('${s.reps} reps • ${s.weight} kg • ${s.time.inSeconds}s', style: AppTextStyles.bodySmall.copyWith(color: AppColors.textSecondary)),
                                  ],
                                )),
                          ],
                        ),
                      ),
                    ],
                    const Spacer(),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        SizedBox(
                          width: buttonWidth,
                          child: ElevatedButton.icon(
                            onPressed: _isTimerRunning ? _stopSet : _startSet,
                            icon: Icon(_isTimerRunning ? Icons.stop : Icons.play_arrow),
                            label: Text(_isTimerRunning ? 'STOP SET' : 'START SET'),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _PersonalBreakOverlay extends StatefulWidget {
  final String title;
  final VoidCallback onDone;
  const _PersonalBreakOverlay({required this.title, required this.onDone});

  @override
  State<_PersonalBreakOverlay> createState() => _PersonalBreakOverlayState();
}

class _PersonalBreakOverlayState extends State<_PersonalBreakOverlay> {
  int _elapsed = 0;
  Timer? _t;

  @override
  void initState() {
    super.initState();
    _t = Timer.periodic(const Duration(seconds: 1), (_) {
      setState(() => _elapsed++);
    });
  }

  @override
  void dispose() {
    _t?.cancel();
    super.dispose();
  }

  String _fmt(int s) {
    final m = s ~/ 60;
    final r = s % 60;
    return '${m.toString().padLeft(2, '0')}:${r.toString().padLeft(2, '0')}';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF1a1a1a),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                widget.title,
                style: AppTextStyles.titleLarge.copyWith(
                  color: Colors.white,
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 2,
                ),
              ),
              const SizedBox(height: 40),
              Text(
                _fmt(_elapsed),
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 48,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 24),
              ElevatedButton(
                onPressed: widget.onDone,
                child: const Text('Continue'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
