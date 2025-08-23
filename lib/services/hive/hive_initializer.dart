import 'package:hive_flutter/hive_flutter.dart';
import 'adapters/hive_personal_workout.dart';
import 'adapters/hive_workout.dart';
import 'adapters/hive_user.dart';

/// Central place to initialize Hive & register all adapters exactly once.
class HiveInitializer {
  static bool _initialized = false;

  static Future<void> init() async {
    if (_initialized) return;
    await Hive.initFlutter();

    // Explicit generic registrations prevent dynamic adapter dispatch bugs.
    if (!Hive.isAdapterRegistered(
      HivePersonalWorkoutExerciseAdapter().typeId,
    )) {
      Hive.registerAdapter<HivePersonalWorkoutExercise>(
        HivePersonalWorkoutExerciseAdapter(),
      );
    }
    if (!Hive.isAdapterRegistered(HivePersonalWorkoutAdapter().typeId)) {
      Hive.registerAdapter<HivePersonalWorkout>(HivePersonalWorkoutAdapter());
    }
    if (!Hive.isAdapterRegistered(HiveWorkoutAdapter().typeId)) {
      Hive.registerAdapter<HiveWorkout>(HiveWorkoutAdapter());
    }
    if (!Hive.isAdapterRegistered(HiveWorkoutExerciseAdapter().typeId)) {
      Hive.registerAdapter<HiveWorkoutExercise>(HiveWorkoutExerciseAdapter());
    }
    if (!Hive.isAdapterRegistered(HiveWorkoutSetAdapter().typeId)) {
      Hive.registerAdapter<HiveWorkoutSet>(HiveWorkoutSetAdapter());
    }
    if (!Hive.isAdapterRegistered(HiveUserAuthAdapter().typeId)) {
      Hive.registerAdapter<HiveUserAuth>(HiveUserAuthAdapter());
    }

    _initialized = true;
  }
}
