import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../constants/app_styles.dart';
import '../services/auth_service.dart';
import '../blocs/workout_bloc.dart';
import 'free_workout_screens/free_workout_screen.dart';
import 'login_screen.dart';
import 'custom_workout_screens/custom_workouts_screen.dart';

class MainScreen extends StatefulWidget {
  const MainScreen({super.key});

  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  final AuthService _authService = AuthService();
  int _currentIndex = 0;

  final List<Widget> _screens = [
    const FreeWorkoutScreen(),
    const PredefinedWorkoutsScreen(),
  ];

  Future<void> _signOut() async {
    await _authService.signOut();
    if (mounted) {
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(builder: (context) => const LoginScreen()),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return BlocListener<WorkoutBloc, WorkoutState>(
      listener: (context, state) {
        if (state is WorkoutError) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(state.message),
              backgroundColor: Colors.red,
            ),
          );
        }
      },
      child: Scaffold(
        backgroundColor: AppColors.background,
        appBar: AppBar(
          title: Text('GymPad', style: AppTextStyles.appBarTitle),
          backgroundColor: AppColors.background,
          elevation: 0,
          actions: [
            IconButton(
              onPressed: _signOut,
              icon: Icon(Icons.logout, color: AppColors.primary),
            ),
          ],
        ),
        body: IndexedStack(
          index: _currentIndex,
          children: _screens,
        ),
        bottomNavigationBar: BottomNavigationBar(
          currentIndex: _currentIndex,
          onTap: (index) {
            setState(() {
              _currentIndex = index;
            });
          },
          backgroundColor: AppColors.white,
          selectedItemColor: AppColors.primary,
          unselectedItemColor: AppColors.textSecondary,
          type: BottomNavigationBarType.fixed,
          items: const [
            BottomNavigationBarItem(
              icon: Icon(Icons.fitness_center),
              label: 'Free Workout',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.list_alt),
              label: 'Custom Workout',
            ),
          ],
        ),
      ),
    );
  }
}