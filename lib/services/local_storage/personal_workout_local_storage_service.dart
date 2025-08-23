import '../api/models/workout_models.dart';
import '../../models/personal_workout.dart';
import 'base_local_storage_service.dart';

/// Local persistence for Personal Workouts using SharedPreferences.
class PersonalWorkoutLocalService extends BaseLocalStorageService {
  static final PersonalWorkoutLocalService _instance =
      PersonalWorkoutLocalService._internal();
  factory PersonalWorkoutLocalService() => _instance;
  PersonalWorkoutLocalService._internal();

  static const String _storageKey = 'personal_workouts';

  Future<void> saveAll(List<PersonalWorkoutResponse> workouts) async {
    final list = workouts.map((w) => w.toJson()).toList();
    await writeJson(_storageKey, list);
  }

  Future<List<PersonalWorkout>> loadAll() async {
    final decoded = await readJson(_storageKey);
    if (decoded == null) return [];
    if (decoded is List) {
      try {
        return decoded
            .whereType<Map<String, dynamic>>()
            .map((e) => PersonalWorkout.fromJson(e))
            .toList();
      } catch (_) {
        await remove(_storageKey);
        return [];
      }
    }
    await remove(_storageKey);
    return [];
  }

  Future<void> clear() async {
    await remove(_storageKey);
  }
}
