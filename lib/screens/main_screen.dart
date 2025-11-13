import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../blocs/auth/auth_bloc.dart';
import '../constants/app_styles.dart';
import 'me/me.dart';
import 'workouts/workout_page.dart';

class MainScreen extends StatefulWidget {
  final int defaultIndex; // initial workouts tab index
  const MainScreen({super.key, this.defaultIndex = 0});

  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  int _bottomIndex = 0; // 0 = Workouts, 1 = Me

  @override
  void initState() {
    super.initState();
  }

  BottomNavigationBar _buildBottomNav() => BottomNavigationBar(
    currentIndex: _bottomIndex,
    onTap: (i) => setState(() => _bottomIndex = i),
    backgroundColor: AppColors.white,
    selectedItemColor: AppColors.primary,
    unselectedItemColor: AppColors.textSecondary,
    items: const [
      BottomNavigationBarItem(
        icon: Icon(Icons.fitness_center),
        label: 'Workouts',
      ),
      BottomNavigationBarItem(icon: Icon(Icons.person_outline), label: 'Me'),
    ],
  );

  PreferredSizeWidget _buildAppBar({
    PreferredSizeWidget? bottom,
    bool settings = false,
  }) {
    final actions = <Widget>[];
    if (settings) {
      actions.add(
        IconButton(
          tooltip: 'Settings',
          onPressed: () => context.push('/settings'),
          icon: Icon(Icons.settings, color: AppColors.primary),
        ),
      );
    }
    return AppBar(
      title: Text('GymPad', style: AppTextStyles.appBarTitle),
      backgroundColor: AppColors.background,
      elevation: 0,
      actions: actions,
      bottom: bottom,
    );
  }

  @override
  Widget build(BuildContext context) {
    Widget page;
    if (_bottomIndex == 0) {
      page = DefaultTabController(
        length: 3,
        initialIndex: widget.defaultIndex.clamp(0, 2),
        child: Scaffold(
          backgroundColor: AppColors.background,
          appBar: _buildAppBar(
            bottom: PreferredSize(
              preferredSize: const Size.fromHeight(56),
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
                child: const _TopTabSlider(),
              ),
            ),
          ),
          body: const WorkoutPage(),
          bottomNavigationBar: _buildBottomNav(),
        ),
      );
    } else {
      page = Scaffold(
        backgroundColor: AppColors.background,
        appBar: _buildAppBar(settings: true),
        body: const MeScreen(),
        bottomNavigationBar: _buildBottomNav(),
      );
    }

    return BlocListener<AuthBloc, AuthState>(
      listenWhen: (prev, curr) => prev.runtimeType != curr.runtimeType,
      listener: (context, state) {
        if (state is AuthUnauthenticated) {
          context.go('/login');
        }
      },
      child: page,
    );
  }
}

class _TopTabSlider extends StatelessWidget {
  const _TopTabSlider();
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
