import 'package:cloud_firestore/cloud_firestore.dart';

class AnalyticsService {
  AnalyticsService._internal();
  static final AnalyticsService instance = AnalyticsService._internal();

  final DocumentReference _counterDoc = FirebaseFirestore.instance
      .collection('appMetrics')
      .doc('counters');

  /// Increments the number of times the app has been opened
  Future<void> incrementAppOpen() {
    return _counterDoc.set({
      'appOpens': FieldValue.increment(1),
    }, SetOptions(merge: true));
  }

  /// Increments the number of exercises completed
  Future<void> incrementExerciseComplete() {
    return _counterDoc.set({
      'exerciseCompletions': FieldValue.increment(1),
    }, SetOptions(merge: true));
  }
}
