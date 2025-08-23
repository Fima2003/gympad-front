import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../constants/app_styles.dart';
import '../services/auth_service.dart';
import '../blocs/workout_bloc.dart';
import 'free_workout_screens/free_workout_screen.dart';
import 'login_screen.dart';
import 'custom_workout_screens/custom_workouts_screen.dart';
import 'personal_workout_screens/personal_workouts_screen.dart';

class MainScreen extends StatefulWidget {
  const MainScreen({super.key});

  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  final AuthService _authService = AuthService();
  bool _isSigningOut = false;

  final List<Widget> _screens = [
    const FreeWorkoutScreen(),
    const PredefinedWorkoutsScreen(),
    const PersonalWorkoutsScreen(),
  ];

  @override
  void initState() {
    super.initState();
    // Let the BLoC handle syncing personal workouts
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<WorkoutBloc>().add(PersonalWorkoutsSyncRequested());
    });
  }

  Future<void> _signOut() async {
    setState(() => _isSigningOut = true);
    try {
      await _authService.signOut();
      if (!mounted) return;
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(builder: (context) => const LoginScreen()),
      );
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to sign out: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isSigningOut = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 3,
      child: Stack(
        children: [
          BlocListener<WorkoutBloc, WorkoutState>(
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
                bottom: PreferredSize(
                  preferredSize: const Size.fromHeight(56),
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
                    child: _TopTabSlider(),
                  ),
                ),
              ),
              body: TabBarView(children: _screens),
              // bottomNavigationBar: BottomNavigationBar(
              //   currentIndex: 0,
              //   onTap: (_) {},
              //   backgroundColor: AppColors.white,
              //   selectedItemColor: AppColors.primary,
              //   unselectedItemColor: AppColors.textSecondary,
              //   type: BottomNavigationBarType.fixed,
              //   items: const [
              //     BottomNavigationBarItem(
              //       icon: Icon(Icons.dashboard_customize),
              //       label: 'Workouts',
              //     ),
              //   ],
              // ),
            ),
          ),
          if (_isSigningOut) ...[
            const ModalBarrier(dismissible: false, color: Colors.black26),
            Center(
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 20,
                  vertical: 16,
                ),
                decoration: BoxDecoration(
                  color: AppColors.background,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: AppColors.accent.withValues(alpha: 0.4),
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.1),
                      blurRadius: 8,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    SizedBox(
                      width: 22,
                      height: 22,
                      child: CircularProgressIndicator(
                        strokeWidth: 3,
                        valueColor: AlwaysStoppedAnimation<Color>(
                          AppColors.primary,
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Text(
                      'Signing you out…',
                      style: AppTextStyles.bodyMedium.copyWith(
                        color: AppColors.primary,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _TopTabSlider extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      height: 44,
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.accent),
      ),
      child: TabBar(
        dividerColor: Colors.transparent,
        dividerHeight: 0,
        indicator: BoxDecoration(
          color: AppColors.primary,
          borderRadius: BorderRadius.circular(8),
        ),
        indicatorSize: TabBarIndicatorSize.tab,
        labelColor: Colors.white,
        unselectedLabelColor: AppColors.primary,
        labelStyle: AppTextStyles.bodyMedium.copyWith(
          fontWeight: FontWeight.w700,
        ),
        unselectedLabelStyle: AppTextStyles.bodyMedium,
        tabs: const [
          Tab(text: 'Free'),
          Tab(text: 'Custom'),
          Tab(text: 'Personal'),
        ],
      ),
    );
  }
}
