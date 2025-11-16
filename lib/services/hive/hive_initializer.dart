import 'package:hive_flutter/hive_flutter.dart';
import '../../models/withAdapters/exercise.dart';
import '../../models/withAdapters/questionnaire.dart';
import '../../models/withAdapters/user.dart';
import '../../models/withAdapters/user_settings.dart';
import 'adapters/hive_personal_workout.dart';
import 'adapters/hive_workout.dart';
import 'adapters/hive_custom_workout.dart';
import 'adapters/hive_notification_settings.dart';

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
    if (!Hive.isAdapterRegistered(ExerciseAdapter().typeId)) {
      Hive.registerAdapter<Exercise>(ExerciseAdapter());
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
    if (!Hive.isAdapterRegistered(UserAdapter().typeId)) {
      Hive.registerAdapter<User>(UserAdapter());
    }
    if (!Hive.isAdapterRegistered(HiveCustomWorkoutExerciseAdapter().typeId)) {
      Hive.registerAdapter<HiveCustomWorkoutExercise>(
        HiveCustomWorkoutExerciseAdapter(),
      );
    }
    if (!Hive.isAdapterRegistered(HiveCustomWorkoutAdapter().typeId)) {
      Hive.registerAdapter<HiveCustomWorkout>(HiveCustomWorkoutAdapter());
    }
    if (!Hive.isAdapterRegistered(QuestionnaireAdapter().typeId)) {
      Hive.registerAdapter<Questionnaire>(QuestionnaireAdapter());
    }
    if (!Hive.isAdapterRegistered(UserSettingsAdapter().typeId)) {
      Hive.registerAdapter<UserSettings>(UserSettingsAdapter());
    }
    // The one below is 11 (started from 0)
    if (!Hive.isAdapterRegistered(UserLevelAdapter().typeId)) {
      Hive.registerAdapter<UserLevel>(UserLevelAdapter());
    }
    if (!Hive.isAdapterRegistered(HiveNotificationSettingsAdapter().typeId)) {
      Hive.registerAdapter<HiveNotificationSettings>(
        HiveNotificationSettingsAdapter(),
      );
    }

    _initialized = true;
  }
}
