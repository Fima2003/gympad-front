import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter/services.dart';

import '../../../../constants/app_styles.dart';

import '../../../../blocs/save_workout/save_workout_bloc.dart';
import '../../../../models/workout_exercise.dart';
import '../../../../models/workout_set.dart';

part 'save_workout_exercises_view.dart';
part 'save_workout_info_view.dart';
part 'save_workout_edit_exercise.dart';

class SaveWorkoutScreen extends StatefulWidget {
  final List<WorkoutExercise> exercises;
  const SaveWorkoutScreen({super.key, required this.exercises});

  @override
  State<SaveWorkoutScreen> createState() => _SaveWorkoutScreenState();
}

class _SaveWorkoutScreenState extends State<SaveWorkoutScreen> {
  @override
  Widget build(BuildContext context) {
    return BlocProvider<SaveWorkoutBloc>(
      create:
          (_) =>
              SaveWorkoutBloc()..add(SaveWorkoutSetExercises(widget.exercises)),
      child: BlocConsumer<SaveWorkoutBloc, SaveWorkoutState>(
        listener: (context, state) {
          if (state is SaveWorkoutExercises && state.editIndex != null) {
            // Defer to after build frame.
            WidgetsBinding.instance.addPostFrameCallback((_) {
              if (!mounted) return;
              final parentContext = context; // capture provider scope
              final bloc = parentContext.read<SaveWorkoutBloc>();
              final editIdx = state.editIndex!;
              final originalExercise = state.exercises[editIdx];
              showModalBottomSheet(
                context: parentContext,
                enableDrag: false,
                isDismissible: false,
                isScrollControlled: true,
                builder: (sheetContext) {
                  return SaveWorkoutEditExerciseWidget(
                    sets: originalExercise.sets,
                    exerciseName: originalExercise.name,
                    onDone: (updatedSets) {
                      Navigator.of(sheetContext).pop();
                      bloc.add(
                        SaveWorkoutUpdateExercise(
                          editIdx,
                          originalExercise.copyWith(sets: updatedSets),
                        ),
                      );
                    },
                  );
                },
              ).whenComplete(() {
                if (!mounted) return;
                bloc.add(SaveWorkoutCloseEditor());
              });
            });
          } else if (state is SaveWorkoutSuccess && state.success) {
            Navigator.of(context).popUntil((route) => route.isFirst);
          }
        },
        buildWhen: (previous, current) {
          // Rebuild for all states except throttle SaveWorkoutExercises to editIndex changes
          // so we don't trigger unnecessary rebuilds while editing sets in the bottom sheet.
          if (current is SaveWorkoutExercises &&
              previous is SaveWorkoutExercises) {
            return current.editIndex != previous.editIndex;
          }
          return true;
        },
        builder: (context, state) {
          Widget content;
          if (state is SaveWorkoutExercises) {
            content = SaveWorkoutExercisesView(
              exercises: state.exercises,
              onEdit: (index) {
                BlocProvider.of<SaveWorkoutBloc>(
                  context,
                ).add(SaveWorkoutEditExercise(index));
              },
            );
          } else if (state is SaveWorkoutInfo || state is SaveWorkoutError) {
            content = SaveWorkoutInfoView(
              initialName:
                  state is SaveWorkoutInfo
                      ? state.name
                      : state is SaveWorkoutError
                      ? state.name
                      : '',
              initialDescription:
                  state is SaveWorkoutInfo
                      ? state.description
                      : state is SaveWorkoutError
                      ? state.description
                      : '',
              onDescriptionChanged: (name) {
                BlocProvider.of<SaveWorkoutBloc>(
                  context,
                ).add(SaveWorkoutUpdateDescription(name));
              },
              onNameChanged: (name) {
                BlocProvider.of<SaveWorkoutBloc>(
                  context,
                ).add(SaveWorkoutUpdateName(name));
              },
              nameError: state is SaveWorkoutError ? state.nameError : null,
              descriptionError:
                  state is SaveWorkoutError ? state.descriptionError : null,
            );
            // Keep logic the same; overlay handled below in the Scaffold body
          } else {
            content = const Center(child: CircularProgressIndicator());
          }

          final isInfo = state is SaveWorkoutInfo || state is SaveWorkoutError;
          final isUploading = state is SaveWorkoutInfo && state.uploading;

          return Scaffold(
            backgroundColor: AppColors.background,
            appBar: AppBar(
              backgroundColor: AppColors.background,
              elevation: 0,
              title: Text(
                isInfo ? 'Edit Info' : 'Edit Exercises',
                style: AppTextStyles.appBarTitle,
              ),
            ),
            body: Stack(
              children: [
                SafeArea(
                  child: Column(
                    children: [
                      // Content area
                      Expanded(
                        child: SingleChildScrollView(
                          padding: const EdgeInsets.all(16),
                          child: content,
                        ),
                      ),
                      // Bottom action bar
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.fromLTRB(16, 12, 16, 20),
                        decoration: BoxDecoration(
                          color: AppColors.white,
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withValues(alpha: 0.06),
                              blurRadius: 10,
                              offset: const Offset(0, -2),
                            ),
                          ],
                        ),
                        child: Row(
                          children: [
                            if (!isInfo) ...[
                              Expanded(
                                child: SizedBox(
                                  height: 52,
                                  child: ElevatedButton(
                                    onPressed: () {
                                      BlocProvider.of<SaveWorkoutBloc>(
                                        context,
                                      ).add(SaveWorkoutSwitch(true));
                                    },
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: AppColors.primary,
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(12),
                                      ),
                                    ),
                                    child: Text(
                                      'Next',
                                      style: AppTextStyles.button.copyWith(
                                        color: Colors.white,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                            ] else ...[
                              Expanded(
                                child: SizedBox(
                                  height: 48,
                                  child: OutlinedButton(
                                    onPressed:
                                        isUploading
                                            ? null
                                            : () {
                                              BlocProvider.of<SaveWorkoutBloc>(
                                                context,
                                              ).add(SaveWorkoutSwitch(false));
                                            },
                                    style: OutlinedButton.styleFrom(
                                      side: BorderSide(
                                        color: AppColors.primary,
                                        width: 1.5,
                                      ),
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(12),
                                      ),
                                    ),
                                    child: Text(
                                      'Back',
                                      style: AppTextStyles.button.copyWith(
                                        color: AppColors.primary,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: SizedBox(
                                  height: 52,
                                  child: ElevatedButton(
                                    onPressed:
                                        isUploading
                                            ? null
                                            : () {
                                              BlocProvider.of<SaveWorkoutBloc>(
                                                context,
                                              ).add(SaveWorkoutUpload());
                                            },
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: AppColors.primary,
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(12),
                                      ),
                                    ),
                                    child: Text(
                                      'Save',
                                      style: AppTextStyles.button.copyWith(
                                        color: Colors.white,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ],
                        ),
                      ),
                    ],
                  ),
                ),

                if (isUploading) ...[
                  Positioned.fill(
                    child: Container(
                      color: Colors.black.withValues(alpha: 0.25),
                      child: const Center(child: CircularProgressIndicator()),
                    ),
                  ),
                ],
              ],
            ),
          );
        },
      ),
    );
  }
}
