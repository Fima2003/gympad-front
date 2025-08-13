import 'package:flutter/material.dart';
import 'dart:ui';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:gympad/firebase_options.dart';
import 'package:gympad/services/api/api.dart';
import 'services/analytics_service.dart';
import 'services/auth_service.dart';
import 'services/logger_service.dart';
import 'constants/app_styles.dart';
import 'services/data_service.dart';
import 'blocs/workout_bloc.dart';
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
    logger.error('FlutterError: ${details.exception}', details.exception, details.stack);
  };
  
  ApiService().initialize();
  
  // Catch all uncaught errors
  PlatformDispatcher.instance.onError = (error, stack) {
    logger.error('Uncaught Dart error', error, stack);
    return true; // Prevent default handling
  };
  
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider<WorkoutBloc>(
      create: (context) => WorkoutBloc()..add(WorkoutLoaded()),
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
  final AuthService _authService = AuthService();
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
    if (_authService.isSignedIn) {
      try {
        final ok = await _authService.fetchUserOnAppStartWithRetry();
        _logger.info('Splash: backend user fetch ${ok ? 'succeeded' : 'failed'}');
      } catch (e, st) {
        _logger.warning('Splash: backend user fetch failed', e, st);
      }
    }

    // Check local user auth state (fallback navigation)
    final localUserData = await _authService.getLocalUserData();
    final userId = localUserData['userId'];
    _logger.info('Splash: local userId=$userId');

    if (!mounted) return;

  // Proceed to Main/Login
    setState(() => _isLoading = false);
    if (_navigated || !mounted) return;
    _navigated = true;
    if (userId != null) {
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(builder: (context) => const MainScreen()),
      );
    } else {
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(builder: (context) => const LoginScreen()),
      );
    }
  }

  // No deep-link error dialogs needed; keeping UI clean.

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return Scaffold(
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
              CircularProgressIndicator(color: AppColors.primary),
              const SizedBox(height: 16),
              Text(
                'Loading gym data...',
                style: AppTextStyles.bodyMedium.copyWith(
                  color: AppColors.textSecondary,
                ),
              ),
            ],
          ),
        ),
      );
    }

    return Scaffold(
      backgroundColor: AppColors.background,
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(40),
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
              const SizedBox(height: 24),
              Text(
                'Scan an NFC tag to get started!',
                style: AppTextStyles.titleMedium.copyWith(
                  color: AppColors.textSecondary,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 40),
              Container(
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  color: AppColors.accent.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: AppColors.accent, width: 2),
                ),
                child: Column(
                  children: [
                    Icon(Icons.nfc, size: 64, color: AppColors.primary),
                    const SizedBox(height: 16),
                    Text(
                      'Ready to scan',
                      style: AppTextStyles.bodyLarge.copyWith(
                        fontWeight: FontWeight.w600,
                        color: AppColors.primary,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 60),

              // Development Mode Button
              Container(
                width: double.infinity,
                margin: const EdgeInsets.symmetric(horizontal: 20),
              ),

              const SizedBox(height: 20),

              Text(
                'This is a test application.\nAll data is saved locally on your device.',
                style: AppTextStyles.bodySmall.copyWith(
                  fontStyle: FontStyle.italic,
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
