import 'package:flutter_test/flutter_test.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:gympad/services/hive/personal_workout_lss.dart';
import 'package:gympad/services/api/models/workout_models.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late PersonalWorkoutLocalService service;

  setUp(() async {
    await Hive.initFlutter();
    // Clean up any existing boxes
    // Ensure any leftover boxes from previous runs are closed.
    if (Hive.isBoxOpen('personal_workouts_box')) {
      await Hive.box('personal_workouts_box').close();
    }
    service = PersonalWorkoutLocalService();
  });

  tearDown(() async {
    if (Hive.isBoxOpen('personal_workouts_box')) {
      final box = Hive.box('personal_workouts_box');
      await box.deleteFromDisk();
    }
  });

  group('PersonalWorkoutLocalService (Hive)', () {
    test('saveAll then loadAll returns equivalent domain models', () async {
      final workouts = [
        PersonalWorkoutResponse(
          name: 'Leg Day',
          description: 'Strength focus',
          exercises: [
            PersonalWorkoutExerciseDto(
              exerciseId: 'squat',
              name: 'Barbell Squat',
              sets: 5,
              reps: 5,
              weight: 100.0,
              restTime: 180,
            ),
          ],
        ),
        PersonalWorkoutResponse(
          name: 'Push',
          description: 'Chest & Tris',
          exercises: [
            PersonalWorkoutExerciseDto(
              exerciseId: 'bench',
              name: 'Bench Press',
              sets: 3,
              reps: 8,
              weight: 80.0,
              restTime: 120,
            ),
          ],
        ),
      ];

      await service.saveAll(workouts);
      final loaded = await service.loadAll();

      expect(loaded.length, workouts.length);
      expect(loaded.first.name, workouts.first.name);
      expect(loaded.first.exercises.first.name, 'Barbell Squat');
    });

    test('clear removes all workouts', () async {
      final workouts = [
        PersonalWorkoutResponse(
          name: 'Temp',
          description: null,
          exercises: [
            PersonalWorkoutExerciseDto(
              exerciseId: 'x',
              name: 'X',
              sets: 1,
              reps: 10,
              weight: 10.0,
              restTime: 60,
            ),
          ],
        ),
      ];
      await service.saveAll(workouts);
      expect((await service.loadAll()).isNotEmpty, true);
      await service.clear();
      expect(await service.loadAll(), isEmpty);
    });
  });
}
