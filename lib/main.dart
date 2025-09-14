import 'dart:async';

import 'package:flutter/material.dart';
import 'dart:ui';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:gympad/blocs/analytics/analytics_bloc.dart';
import 'package:gympad/firebase_options.dart';
import 'package:gympad/models/workout_exercise.dart';
import 'package:gympad/services/api/api.dart';
import 'blocs/personal_workouts/personal_workout_bloc.dart';
import 'models/custom_workout.dart';
import 'models/personal_workout.dart';
import 'screens/workouts/free_workout_screens/save_workout/save_workout_screen.dart';
import 'screens/workouts/well_done_workout_screen.dart';
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
import 'services/migration/migrate_guest_workouts_usecase.dart';
import 'blocs/auth/auth_bloc.dart';
import 'blocs/audio/audio_bloc.dart';
import 'screens/login_screen.dart';
import 'screens/main_screen.dart';
import 'models/workout.dart';
import 'screens/questionnaire/questionnaire_screen.dart';
import 'services/hive/questionnaire_lss.dart';

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

class MyApp extends StatefulWidget {
  const MyApp({super.key});

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  late final GoRouter _router;

  @override
  void initState() {
    super.initState();
    // Build router once to avoid resetting to '/' on hot reload.
    _router = GoRouter(
      initialLocation: '/',
      routes: [
        GoRoute(path: '/', builder: (context, state) => const SplashScreen()),
        GoRoute(
          path: '/questionnaire',
          builder: (context, state) {
            final force = state.uri.queryParameters['force'] == 'true';
            return QuestionnaireScreen(force: force);
          },
        ),
        GoRoute(path: '/main', builder: (context, state) => const MainScreen()),
        GoRoute(
          path: '/login',
          builder: (context, state) => const LoginScreen(),
        ),
        GoRoute(
          path: '/workout',
          builder: (context, state) => const MainScreen(defaultIndex: 0),
          routes: [
            GoRoute(
              path: 'custom',
              builder: (context, state) => const MainScreen(defaultIndex: 1),
              routes: [
                GoRoute(
                  path: 'run',
                  builder: (context, state) => CWorkoutRunScreen(),
                ),
                GoRoute(
                  path: 'details',
                  builder: (context, state) {
                    final workout = state.extra as CustomWorkout?;
                    if (workout == null) {
                      return const Scaffold(
                        body: Center(
                          child: Text('No workout details available.'),
                        ),
                      );
                    }
                    return PredefinedWorkoutDetailScreen(workout: workout);
                  },
                ),
              ],
            ),
            GoRoute(
              path: 'free',
              builder: (context, state) => const MainScreen(defaultIndex: 0),
              routes: [
                GoRoute(
                  path: 'run',
                  builder: (context, state) => FreeWorkoutRunScreen(),
                ),
                GoRoute(
                  path: 'save',
                  builder:
                      (context, state) => SaveWorkoutScreen(
                        exercises: state.extra as List<WorkoutExercise>,
                      ),
                ),
              ],
            ),
            GoRoute(
              path: 'personal',
              builder: (context, state) => const MainScreen(defaultIndex: 2),
              routes: [
                GoRoute(
                  path: 'details',
                  builder: (context, state) {
                    final workout = state.extra as PersonalWorkout?;
                    if (workout == null) {
                      return const Scaffold(
                        body: Center(
                          child: Text('No workout details available.'),
                        ),
                      );
                    }
                    return PersonalWorkoutDetailScreen(workout: workout);
                  },
                ),
              ],
            ),
            GoRoute(
              path: 'prepare-to-start',
              builder: (context, state) {
                final workout = state.extra as CustomWorkout?;
                if (workout == null) {
                  return const Scaffold(
                    body: Center(child: Text('No workout to prepare.')),
                  );
                }
                return PrepareToStartWorkoutScreen(workout: workout);
              },
            ),
            GoRoute(
              path: 'well-done',
              builder: (context, state) {
                final workout = state.extra as Workout?;
                if (workout == null) {
                  return const Scaffold(
                    body: Center(child: Text('No workout details available.')),
                  );
                }
                return WellDoneWorkoutScreen(workout: workout);
              },
            ),
          ],
        ),
      ],
    );
  }

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
            WorkoutService().configureCapabilitiesProvider(() {
              final authState = context.read<AuthBloc>().state;
              if (authState is AuthAuthenticated) {
                return Capabilities.authenticated;
              }
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
          create: (context) => PersonalWorkoutBloc(),
        ),
      ],
      child: BlocListener<AuthBloc, AuthState>(
        listener: (context, state) {
          unawaited(() async {
            final useCase = MigrateGuestWorkoutsUseCase(
              capabilitiesProvider: () {
                final s = context.read<AuthBloc>().state;
                if (s is AuthAuthenticated) return Capabilities.authenticated;
                if (s is AuthGuest) return Capabilities.guest;
                return Capabilities.guest;
              },
            );
            await useCase.run();
            await WorkoutService().uploadPendingWorkouts();
          }());
        },
        listenWhen:
            (previous, current) =>
                previous is AuthGuest && current is AuthAuthenticated,
        child: MaterialApp.router(
          title: 'GymPad',
          debugShowCheckedModeBanner: false,
          theme: ThemeData(
            colorScheme: ColorScheme.fromSeed(seedColor: AppColors.primary),
            useMaterial3: true,
            scaffoldBackgroundColor: AppColors.background,
          ),
          routerConfig: _router,
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
  final _questionnaireLss = QuestionnaireLocalStorageService();
  final _questionnaireApi = QuestionnaireApiService();

  Future<void> _retryQuestionnaireUploadIfPending() async {
    try {
      final q = await _questionnaireLss.load();
      if (q != null && (q.completed || q.skipped) && !(q.uploaded)) {
        final req = QuestionnaireSubmitRequest(
          completedAt: q.completedAt,
          answers: q.answers,
        );
        final resp = await _questionnaireApi.submit(req);
        if (resp.success) {
          await _questionnaireLss.save(q.copyWith(uploaded: true));
        }
      }
    } catch (_) {
      // ignore
    }
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // Handle hot reload scenario: if data already loaded, kick auth.
    final dataState = context.read<DataBloc>().state;
    if (_isLoading) {
      // Schedule after build to avoid setState during build warnings.
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _maybeKickAuth(dataState);
      });
    }
  }

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
            if (state is AuthAuthenticated || state is AuthGuest) {
              _navigated = true;
              if (!mounted) return;
              // fire-and-forget retry of questionnaire upload if pending
              unawaited(_retryQuestionnaireUploadIfPending());
              // Before navigating to main/login, ensure questionnaire flow is satisfied
              () async {
                final q = await _questionnaireLss.load();
                final shouldShowQ =
                    !(q?.completed == true || q?.skipped == true);
                if (!mounted) return;
                if (shouldShowQ) {
                  context.go('/questionnaire');
                } else {
                  context.go('/main');
                }
              }();
            } else if (state is AuthUnauthenticated) {
              _navigated = true;
              if (!mounted) return;
              () async {
                final q = await _questionnaireLss.load();
                final shouldShowQ =
                    !(q?.completed == true || q?.skipped == true);
                if (!mounted) return;
                if (shouldShowQ) {
                  context.go('/questionnaire');
                } else {
                  context.go('/login');
                }
              }();
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
