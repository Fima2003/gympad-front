import 'package:flutter/material.dart';

import 'workouts.dart';

class WorkoutPage extends StatelessWidget {
  const WorkoutPage({super.key});

  @override
  Widget build(BuildContext context) {
    return const TabBarView(
      children: [
        FreeWorkoutScreen(),
        CustomWorkoutsScreen(),
        PersonalWorkoutsScreen(),
      ],
    );
  }
}
