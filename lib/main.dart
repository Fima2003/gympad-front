import 'package:flutter/material.dart';
import 'dart:ui';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:gympad/firebase_options.dart';
import 'package:gympad/services/api/api.dart';
import 'services/hive/hive_initializer.dart';
import 'services/analytics_service.dart';
import 'services/logger_service.dart';
import 'constants/app_styles.dart';
import 'services/data_service.dart';
import 'blocs/workout/workout_bloc.dart';
import 'blocs/auth/auth_bloc.dart';
import 'screens/login_screen.dart';
import 'screens/main_screen.dart';

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
        BlocProvider<WorkoutBloc>(
          create: (context) => WorkoutBloc()..add(WorkoutLoaded()),
        ),
        BlocProvider<AuthBloc>(
          create: (context) => AuthBloc(),
        ),
      ],
      child: MaterialApp(
        title: 'GymPad',
        debugShowCheckedModeBanner: false,
        theme: ThemeData(
          colorScheme: ColorScheme.fromSeed(seedColor: AppColors.primary),
          useMaterial3: true,
          scaffoldBackgroundColor: AppColors.background,
        ),
        home: const SplashScreen(),
        routes: {
          '/main': (context) => const MainScreen(),
          '/login': (context) => const LoginScreen(),
        },
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
  final DataService _dataService = DataService();
  final AppLogger _logger = AppLogger();
  bool _isLoading = true;
  bool _navigated = false; // prevent double navigation

  @override
  void initState() {
    super.initState();
    // Perform startup flow: load data, then navigate to main/login
    _startupFlow();
  }

  Future<void> _startupFlow() async {
    _logger.info('Splash: startupFlow begin');
    // Load local data required for navigation
    await _dataService.loadData();
    _logger.debug('Splash: data loaded');

    // Track app open in Firestore (safely)
    try {
      await AnalyticsService.instance.incrementAppOpen();
      _logger.debug('Splash: analytics app open incremented');
    } catch (e, st) {
      _logger.warning('AnalyticsService.incrementAppOpen failed', e, st);
    }

    // If signed in, fetch user from backend (refresh token and retry if needed)
  if (!mounted) return;
  // Kick off auth determination after data work
  context.read<AuthBloc>().add(AuthAppStarted());
  setState(() => _isLoading = false);
  }

  // No deep-link error dialogs needed; keeping UI clean.

  @override
  Widget build(BuildContext context) {
    return BlocListener<AuthBloc, AuthState>(
      listener: (context, state) {
        if (_navigated) return;
        if (state is AuthAuthenticated) {
          _navigated = true;
          Navigator.of(context).pushReplacement(
            MaterialPageRoute(builder: (_) => const MainScreen()),
          );
        } else if (state is AuthUnauthenticated) {
          _navigated = true;
          Navigator.of(context).pushReplacement(
            MaterialPageRoute(builder: (_) => const LoginScreen()),
          );
        } else if (state is AuthError) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(state.message)),
          );
        }
      },
      child: Scaffold(
        backgroundColor: AppColors.background,
        body: Center(
          child: Column(
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
              if (_isLoading || context.watch<AuthBloc>().state is AuthLoading)
                CircularProgressIndicator(color: AppColors.primary)
              else
                Icon(Icons.nfc, size: 64, color: AppColors.primary),
              const SizedBox(height: 16),
              Text(
                _isLoading ? 'Loading gym data...' : 'Initializing...',
                style: AppTextStyles.bodyMedium.copyWith(
                  color: AppColors.textSecondary,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
