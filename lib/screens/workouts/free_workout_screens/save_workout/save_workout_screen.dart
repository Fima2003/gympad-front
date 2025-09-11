import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter/services.dart';

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
            if (state is SaveWorkoutInfo && state.uploading) {
              print("Uploading...");
              content = Stack(
                children: [
                  content,
                  Positioned.fill(
                    child: AbsorbPointer(
                      absorbing: true,
                      child: Container(color: Colors.black26),
                    ),
                  ),
                  const Center(child: CircularProgressIndicator()),
                ],
              );
            }
          } else {
            content = const Center(child: CircularProgressIndicator());
          }

          return Scaffold(
            appBar: AppBar(
              title: Text(
                state is SaveWorkoutInfo ? 'Edit Info' : 'Edit Exercises',
              ),
            ),
            body: Column(
              children: [
                content,
                Row(
                  children: [
                    if (state is SaveWorkoutExercises) ...[
                      ElevatedButton(
                        onPressed: () {
                          BlocProvider.of<SaveWorkoutBloc>(
                            context,
                          ).add(SaveWorkoutSwitch(true));
                        },
                        child: Text("Next"),
                      ),
                    ] else if (state is SaveWorkoutInfo ||
                        state is SaveWorkoutError) ...[
                      ElevatedButton(
                        onPressed:
                            state is SaveWorkoutInfo && state.uploading
                                ? null
                                : () {
                                  BlocProvider.of<SaveWorkoutBloc>(
                                    context,
                                  ).add(SaveWorkoutSwitch(false));
                                },
                        child: Text("Back"),
                      ),
                      ElevatedButton(
                        onPressed:
                            state is SaveWorkoutInfo && state.uploading
                                ? null
                                : () {
                                  BlocProvider.of<SaveWorkoutBloc>(
                                    context,
                                  ).add(SaveWorkoutUpload());
                                },
                        child: Text("Save"),
                      ),
                    ],
                  ],
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}
