import 'package:flutter/material.dart';
import 'dart:ui';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:gympad/blocs/analytics/analytics_bloc.dart';
import 'package:gympad/firebase_options.dart';
import 'package:gympad/services/api/api.dart';
import 'blocs/personal_workouts/personal_workout_bloc.dart';
import 'models/custom_workout.dart';
import 'models/personal_workout.dart';
import 'screens/well_done_workout_screen.dart';
import 'screens/workouts/custom_workout_screens/custom_workout_detail_screen.dart';
import 'screens/workouts/custom_workout_screens/cworkout_run/cworkout_run_screen.dart';
import 'screens/workouts/custom_workout_screens/prepare_to_start_workout_screen.dart';
import 'screens/workouts/free_workout_screens/free_workout_run/free_workout_run_screen.dart';
import 'screens/workouts/personal_workout_screens/personal_workout_detail_screen.dart';
import 'services/hive/hive_initializer.dart';
import 'services/logger_service.dart';
import 'constants/app_styles.dart';
import 'blocs/data/data_bloc.dart';
import 'blocs/workout/workout_bloc.dart';
import 'models/capabilities.dart';
import 'services/workout_service.dart';
import 'blocs/auth/auth_bloc.dart';
import 'blocs/audio/audio_bloc.dart';
import 'screens/login_screen.dart';
import 'screens/main_screen.dart';
import 'screens/workouts/free_workout_screens/save_workout_screen.dart';
import 'models/workout.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize logger
  AppLogger().initialize();
  final logger = AppLogger();

  // Global Flutter error handler
  FlutterError.onError = (FlutterErrorDetails details) {
    FlutterError.presentError(details);
    // Log to console
    logger.error(
      'FlutterError: ${details.exception}',
      details.exception,
      details.stack,
    );
  };

  ApiService().initialize();

  // Catch all uncaught errors
  PlatformDispatcher.instance.onError = (error, stack) {
    logger.error('Uncaught Dart error', error, stack);
    return true; // Prevent default handling
  };

  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);

  // Initialize Hive & register all adapters centrally
  await HiveInitializer.init();

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiBlocProvider(
      providers: [
        BlocProvider<DataBloc>(
          create: (_) => DataBloc()..add(const DataLoadRequested()),
        ),
        BlocProvider<AuthBloc>(create: (context) => AuthBloc(), lazy: false),
        BlocProvider<WorkoutBloc>(
          create: (context) {
            final bloc = WorkoutBloc();
            // Configure capabilities provider on the singleton WorkoutService.
            // We access AuthBloc lazily inside the provider to always reflect
            // most recent auth state without needing explicit reconfiguration.
            WorkoutService().configureCapabilitiesProvider(() {
              final authState = context.read<AuthBloc>().state;
              if (authState is AuthAuthenticated)
                return Capabilities.authenticated;
              if (authState is AuthGuest) return Capabilities.guest;
              return Capabilities.guest; // default for unauth / loading
            });
            bloc.add(WorkoutLoaded());
            return bloc;
          },
        ),
        BlocProvider<AnalyticsBloc>(create: (context) => AnalyticsBloc()),
        BlocProvider<AudioBloc>(create: (context) => AudioBloc()),
        BlocProvider<PersonalWorkoutBloc>(
          create: (context) => PersonalWorkoutBloc()..add(RequestSync()),
        ),
      ],
      child: MaterialApp.router(
        title: 'GymPad',
        debugShowCheckedModeBanner: false,
        theme: ThemeData(
          colorScheme: ColorScheme.fromSeed(seedColor: AppColors.primary),
          useMaterial3: true,
          scaffoldBackgroundColor: AppColors.background,
        ),
        routerConfig: GoRouter(
          initialLocation: '/',
          routes: [
            GoRoute(
              path: '/',
              builder: (context, state) => const SplashScreen(),
            ),
            GoRoute(
              path: '/main',
              builder: (context, state) => const MainScreen(),
            ),
            GoRoute(
              path: '/login',
              builder: (context, state) => const LoginScreen(),
            ),
            GoRoute(
              path: '/workout',
              builder:(context, state) {
                return const FreeWorkoutRunScreen();
              },
              routes: [
                GoRoute(
                  path: '/run-custom',
                  builder: (context, state) => CWorkoutRunScreen(),
                ),
                GoRoute(
                  path: '/run-free',
                  builder: (context, state) => FreeWorkoutRunScreen(),
                ),
                GoRoute(
                  path: '/save',
                  builder: (context, state) {
                    final workout = state.extra as Workout?;
                    if (workout == null) {
                      // Fallback UI if navigation missing data
                      return const Scaffold(
                        body: Center(child: Text('No workout to save.')),
                      );
                    }
                    return SaveWorkoutScreen(workout: workout);
                  },
                ),
                GoRoute(
                  path: '/details',
                  builder: (context, state) {
                    final workout = state.extra as CustomWorkout?;
                    if (workout == null) {
                      // Fallback UI if navigation missing data
                      return const Scaffold(
                        body: Center(
                          child: Text('No workout details available.'),
                        ),
                      );
                    }
                    return PredefinedWorkoutDetailScreen(workout: workout);
                  },
                ),
                GoRoute(
                  path: '/personal-details',
                  builder: (context, state) {
                    final workout = state.extra as PersonalWorkout?;
                    if (workout == null) {
                      // Fallback UI if navigation missing data
                      return const Scaffold(
                        body: Center(
                          child: Text('No workout details available.'),
                        ),
                      );
                    }
                    return PersonalWorkoutDetailScreen(workout: workout);
                  },
                ),
                GoRoute(
                  path: '/prepare-to-start',
                  builder: (context, state) {
                    final workout = state.extra as CustomWorkout?;
                    if (workout == null) {
                      // Fallback UI if navigation missing data
                      return const Scaffold(
                        body: Center(child: Text('No workout to prepare.')),
                      );
                    }
                    return PrepareToStartWorkoutScreen(workout: workout);
                  },
                ),
                GoRoute(
                  path: '/well-done',
                  builder: (context, state) {
                    final workout = state.extra as Workout?;
                    if (workout == null) {
                      // Fallback UI if navigation missing data
                      return const Scaffold(
                        body: Center(
                          child: Text('No workout details available.'),
                        ),
                      );
                    }
                    return WellDoneWorkoutScreen(workout: workout);
                  },
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  final AppLogger _logger = AppLogger();
  bool _isLoading = true;
  bool _navigated = false;

  void _maybeKickAuth(DataState dataState) {
    if (dataState is DataReady) {
      if (_isLoading) {
        _logger.debug('Splash: data ready, triggering auth');
        context.read<AuthBloc>().add(AuthAppStarted());
        setState(() => _isLoading = false);
      }
    } else if (dataState is DataError) {
      setState(() => _isLoading = false);
    }
  }

  // No deep-link error dialogs needed; keeping UI clean.

  @override
  Widget build(BuildContext context) {
    return MultiBlocListener(
      listeners: [
        BlocListener<DataBloc, DataState>(
          listener: (context, dataState) {
            _maybeKickAuth(dataState);
          },
        ),
        BlocListener<AuthBloc, AuthState>(
          listener: (context, state) {
            if (_navigated) return;
            if (state is AuthAuthenticated) {
              _navigated = true;
              if (!mounted) return;
              // Use GoRouter for navigation (page-based Navigator) instead of imperative pushReplacement
              context.go('/main');
            } else if (state is AuthUnauthenticated) {
              _navigated = true;
              if (!mounted) return;
              context.go('/login');
            } else if (state is AuthError) {
              ScaffoldMessenger.of(
                context,
              ).showSnackBar(SnackBar(content: Text(state.message)));
            }
          },
        ),
      ],
      child: Scaffold(
        backgroundColor: AppColors.background,
        body: Center(
          child: BlocBuilder<DataBloc, DataState>(
            builder: (context, dataState) {
              final authState = context.watch<AuthBloc>().state;
              final loading =
                  dataState is! DataReady ||
                  authState is AuthLoading ||
                  _isLoading;
              return Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    'GymPad',
                    style: AppTextStyles.titleLarge.copyWith(
                      fontSize: 48,
                      fontStyle: FontStyle.italic,
                    ),
                  ),
                  const SizedBox(height: 32),
                  if (loading)
                    CircularProgressIndicator(color: AppColors.primary)
                  else
                    Icon(Icons.nfc, size: 64, color: AppColors.primary),
                  const SizedBox(height: 16),
                  Text(
                    dataState is DataError
                        ? 'Failed to load data'
                        : loading
                        ? 'Loading gym data...'
                        : 'Initializing...',
                    style: AppTextStyles.bodyMedium.copyWith(
                      color: AppColors.textSecondary,
                    ),
                  ),
                ],
              );
            },
          ),
        ),
      ),
    );
  }
}
