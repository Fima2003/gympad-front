import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import '../../../blocs/personal_workouts/personal_workout_bloc.dart';
import '../../../constants/app_styles.dart';
import '../../../models/personal_workout.dart';
import '../../../blocs/data/data_bloc.dart';

class PersonalWorkoutsScreen extends StatefulWidget {
  const PersonalWorkoutsScreen({super.key});

  @override
  State<PersonalWorkoutsScreen> createState() => _PersonalWorkoutsScreenState();
}

class _PersonalWorkoutsScreenState extends State<PersonalWorkoutsScreen> {
  @override
  void initState() {
    super.initState();
    // Request workouts via BLoC on screen initialization
    context.read<PersonalWorkoutBloc>().add(RequestSync());
  }

  // TODO: weird inference of muscle group here; either move to model but also it returns just one mg???
  String _inferMuscleGroup(PersonalWorkout w) {
    final dataState = context.read<DataBloc>().state;
    if (dataState is! DataReady) return '';
    if (w.exercises.isEmpty) return '';
    final first = w.exercises.first;
    final ex = dataState.exercises[first.exerciseId];
    return ex?.muscleGroup[0] ?? '';
  }

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<PersonalWorkoutBloc, PersonalWorkoutState>(
      builder: (context, state) {
        // Determine content based on BLoC state
        final Widget content;
        if (state is PersonalWorkoutsLoading ||
            state is PersonalWorkoutInitial) {
          content = const Center(child: CircularProgressIndicator());
        } else if (state is PersonalWorkoutsLoaded) {
          if (state.workouts.isEmpty) {
            content = Center(
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
            );
          } else {
            content = _list(state.workouts);
          }
        } else {
          content = const Center(child: Text('Unknown state'));
        }

        return MultiBlocListener(
          listeners: [
            BlocListener<DataBloc, DataState>(
              listener: (context, dataState) {
                if (dataState is DataReady && mounted) {
                  // Data became ready after screen opened; trigger rebuild
                  setState(() {});
                }
              },
            ),
          ],
          child: content,
        );
      },
    );
  }

  Widget _list(List<PersonalWorkout> workouts) {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(
                'Personal Workouts',
                style: AppTextStyles.titleLarge.copyWith(
                  fontWeight: FontWeight.bold,
                  color: AppColors.primary,
                ),
              ),
              const SizedBox(width: 8),
              IconButton(
                icon: Icon(
                  Icons.info_outline,
                  color: AppColors.primary,
                  size: 24,
                ),
                onPressed: () {
                  showDialog(
                    context: context,
                    builder:
                        (context) => AlertDialog(
                          title: Row(
                            children: [
                              Icon(
                                Icons.info_outline,
                                color: AppColors.primary,
                              ),
                              const SizedBox(width: 8),
                              Text(
                                'Personal Workouts',
                                style: AppTextStyles.titleMedium,
                              ),
                            ],
                          ),
                          content: Text(
                            'These are the workouts that you build, AI coach or regular coach provides you with. These are smart workouts that are tailored to your goal and smart progression.',
                            style: AppTextStyles.bodyMedium,
                          ),
                          actions: [
                            TextButton(
                              onPressed: () => Navigator.of(context).pop(),
                              child: Text(
                                'Got it',
                                style: AppTextStyles.button.copyWith(
                                  color: AppColors.primary,
                                ),
                              ),
                            ),
                          ],
                        ),
                  );
                },
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(),
              ),
            ],
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
              onRefresh: () async {
                context.read<PersonalWorkoutBloc>().add(RequestSync());
              },
              child: ListView.builder(
                itemCount: workouts.length,
                itemBuilder: (context, index) {
                  final w = workouts[index];
                  final mg = _inferMuscleGroup(w);
                  return Card(
                    margin: const EdgeInsets.only(bottom: 16),
                    elevation: 4,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: InkWell(
                      onTap: () {
                        context.push('/workout/personal/details', extra: w);
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
