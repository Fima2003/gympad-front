part of 'data_bloc.dart';

abstract class DataState extends Equatable {
  const DataState();
  @override
  List<Object?> get props => [];
}

class DataInitial extends DataState {
  const DataInitial();
}

class DataLoading extends DataState {
  const DataLoading();
}

class DataReady extends DataState {
  final Map<String, Exercise> exercises;
  final Map<String, Equipment> equipment;
  const DataReady({required this.exercises, required this.equipment});

  @override
  List<Object?> get props => [exercises, equipment];
}

class DataError extends DataState {
  final String message;
  final Object? error;
  const DataError(this.message, {this.error});
  @override
  List<Object?> get props => [message, error];
}

extension DataSelectors on DataState {
  Exercise? exerciseById(String id) =>
      this is DataReady ? (this as DataReady).exercises[id] : null;
  List<String> allMuscleGroups() {
    if (this is! DataReady) return const [];
    final set = <String>{};
    (this as DataReady).exercises.values.forEach((e) => set.add(e.muscleGroup));
    final list = set.toList()..sort();
    return list;
  }

  List<Exercise> exercisesForMuscleGroup(String mg) {
    if (this is! DataReady) return const [];
    return (this as DataReady).exercises.values
        .where((e) => e.muscleGroup == mg)
        .toList();
  }
}
