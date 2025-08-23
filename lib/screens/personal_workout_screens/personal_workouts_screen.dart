import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../constants/app_styles.dart';
import '../../models/personal_workout.dart';
import '../../services/local_storage/personal_workout_local_storage_service.dart';
import '../../services/data_service.dart';
import '../../blocs/workout_bloc.dart';
import 'personal_workout_detail_screen.dart';

class PersonalWorkoutsScreen extends StatefulWidget {
  const PersonalWorkoutsScreen({super.key});

  @override
  State<PersonalWorkoutsScreen> createState() => _PersonalWorkoutsScreenState();
}

class _PersonalWorkoutsScreenState extends State<PersonalWorkoutsScreen> {
  final PersonalWorkoutLocalService _local = PersonalWorkoutLocalService();
  final DataService _data = DataService();

  List<PersonalWorkout> _workouts = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _init();
    // Trigger a sync via BLoC to update from server if available
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<WorkoutBloc>().add(PersonalWorkoutsSyncRequested());
    });
  }

  Future<void> _init() async {
    await _data.loadData();
    final items = await _local.loadAll();
    if (!mounted) return;
    setState(() {
      _workouts = items;
      _loading = false;
    });
  }

  String _inferMuscleGroup(PersonalWorkout w) {
    if (w.exercises.isEmpty) return '';
    final first = w.exercises.first;
    final ex = _data.getExercise(first.exerciseId);
    return ex?.muscleGroup ?? '';
  }

  @override
  Widget build(BuildContext context) {
    final content =
        (_loading)
            ? const Center(child: CircularProgressIndicator())
            : (_workouts.isEmpty)
            ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.person_outline,
                    size: 64,
                    color: AppColors.textSecondary,
                  ),
                  const SizedBox(height: 12),
                  Text(
                    'No personal workouts yet',
                    style: AppTextStyles.bodyLarge.copyWith(
                      color: AppColors.textSecondary,
                    ),
                  ),
                ],
              ),
            )
            : _list();

    return BlocListener<WorkoutBloc, WorkoutState>(
      listenWhen: (prev, curr) => curr is PersonalWorkoutsLoaded,
      listener: (context, state) {
        if (state is PersonalWorkoutsLoaded) {
          setState(() {
            _workouts = state.workouts;
            _loading = false;
          });
        }
      },
      child: content,
    );
  }

  Widget _list() {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Personal Workouts',
            style: AppTextStyles.titleLarge.copyWith(
              fontWeight: FontWeight.bold,
              color: AppColors.primary,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Your saved workouts',
            style: AppTextStyles.bodyMedium.copyWith(
              color: AppColors.textSecondary,
            ),
          ),
          const SizedBox(height: 20),
          Expanded(
            child: RefreshIndicator(
              onRefresh: _init,
              child: ListView.builder(
                itemCount: _workouts.length,
                itemBuilder: (context, index) {
                  final w = _workouts[index];
                  final mg = _inferMuscleGroup(w);
                  return Card(
                    margin: const EdgeInsets.only(bottom: 16),
                    elevation: 4,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: InkWell(
                      onTap: () {
                        Navigator.of(context).push(
                          MaterialPageRoute(
                            builder:
                                (context) =>
                                    PersonalWorkoutDetailScreen(workout: w),
                          ),
                        );
                      },
                      borderRadius: BorderRadius.circular(16),
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Expanded(
                                  child: Text(
                                    w.name,
                                    style: AppTextStyles.titleMedium.copyWith(
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            if ((w.description ?? '').trim().isNotEmpty) ...[
                              const SizedBox(height: 8),
                              Text(
                                w.description!.trim(),
                                style: AppTextStyles.bodyMedium.copyWith(
                                  color: AppColors.textSecondary,
                                ),
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ],
                            const SizedBox(height: 12),
                            Row(
                              children: [
                                if (mg.isNotEmpty) ...[
                                  Icon(
                                    Icons.fitness_center,
                                    size: 16,
                                    color: AppColors.primary,
                                  ),
                                  const SizedBox(width: 4),
                                  Text(
                                    mg,
                                    style: AppTextStyles.bodySmall.copyWith(
                                      color: AppColors.primary,
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                  const SizedBox(width: 16),
                                ],
                                Icon(
                                  Icons.timer,
                                  size: 16,
                                  color: AppColors.textSecondary,
                                ),
                                const SizedBox(width: 4),
                                Text(
                                  '${w.exercises.length} exercises',
                                  style: AppTextStyles.bodySmall.copyWith(
                                    color: AppColors.textSecondary,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),
          ),
        ],
      ),
    );
  }
}
