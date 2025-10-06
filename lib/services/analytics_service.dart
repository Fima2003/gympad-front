import 'package:cloud_firestore/cloud_firestore.dart';

class AnalyticsService {
  static final AnalyticsService _instance = AnalyticsService._internal();
  factory AnalyticsService() => _instance;
  AnalyticsService._internal();

  final DocumentReference _counterDoc = FirebaseFirestore.instance
      .collection('appMetrics')
      .doc('counters');

  /// Increments the number of times the app has been opened
  Future<void> incrementStartedWorkout() {
    try {
      return _counterDoc.set({
        'startsWorkout': FieldValue.increment(1),
      }, SetOptions(merge: true));
    } catch (e) {
      return Future.value();
    }
  }

  /// Increments the number of exercises completed
  Future<void> incrementWorkoutCompleted() {
    try {
      return _counterDoc.set({
        'exerciseCompletions': FieldValue.increment(1),
      }, SetOptions(merge: true));
    } catch (e) {
      return Future.value();
    }
  }
}
