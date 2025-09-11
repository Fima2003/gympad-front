part of 'save_workout_screen.dart';

class SaveWorkoutExercisesView extends StatelessWidget {
  final List<WorkoutExercise> exercises;
  final void Function(int) onEdit;
  const SaveWorkoutExercisesView({
    super.key,
    required this.exercises,
    required this.onEdit,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children:
          exercises
              .asMap()
              .entries
              .map(
                (e) => Card(
                  child: InkWell(
                    onTap: () => onEdit(e.key),
                    child: ListTile(
                      title: Text(e.value.name),
                      subtitle: Text(
                        'Sets: ${e.value.sets.length}, Average Weight: ${e.value.averageWeight.toStringAsFixed(1)}, muscle groups: ${e.value.muscleGroup}',
                      ),
                    ),
                  ),
                ),
              )
              .toList(),
    );
  }
}
