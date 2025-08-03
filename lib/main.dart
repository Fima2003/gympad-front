import 'package:flutter/material.dart';
import 'package:app_links/app_links.dart';
import 'package:flutter/foundation.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:gympad/firebase_options.dart';
import 'services/analytics_service.dart';
import 'services/auth_service.dart';
import 'constants/app_styles.dart';
import 'services/data_service.dart';
import 'services/url_parsing_service.dart';
import 'screens/exercise_screen.dart';
import 'screens/dev_exercise_selector.dart';
import 'screens/login_screen.dart';
import 'screens/main_screen.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  // Global Flutter error handler
  FlutterError.onError = (FlutterErrorDetails details) {
    FlutterError.presentError(details);
    // Log to console
    print('FlutterError: ${details.exception}');
  };
  // Catch all uncaught errors
  PlatformDispatcher.instance.onError = (error, stack) {
    print('Uncaught Dart error: $error');
    print('Stack trace: $stack');
    return true; // Prevent default handling
  };
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'GymPad',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: AppColors.primary),
        useMaterial3: true,
        scaffoldBackgroundColor: AppColors.background,
      ),
      home: FutureBuilder<Map<String, String?>>(
        future: AuthService().getLocalUserData(),
        builder: (context, snapshot) {
          if (snapshot.connectionState != ConnectionState.done) {
            return const SplashScreen();
          }
          final data = snapshot.data;
          final userId = data?['userId'];
          final gymId = data?['gymId'];
          if (userId != null && gymId != null) {
            return const MainScreen();
          } else {
            return const LoginScreen();
          }
        },
      ),
      routes: {
        '/main': (context) => const MainScreen(),
        '/login': (context) => const LoginScreen(),
      },
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
  late AppLinks _appLinks;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    // load data first, then check auth, then wire up deep links
    _initializeApp().then((_) => _initDeepLinks());
  }

  Future<void> _initializeApp() async {
    await _dataService.loadData();

    // Track app open in Firestore (safely)
    try {
      await AnalyticsService.instance.incrementAppOpen();
    } catch (e, st) {
      // Log analytics errors
      debugPrint('AnalyticsService.incrementAppOpen failed: $e');
      debugPrint('$st');
    }

    // Check if user is locally saved (userId and gymId exist)
    final localUserData = await _authService.getLocalUserData();
    final userId = localUserData['userId'];
    final gymId = localUserData['gymId'];

    setState(() => _isLoading = false);

    if (userId != null && gymId != null) {
      // User is locally saved, navigate to main screen
      if (mounted) {
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(builder: (context) => const MainScreen()),
        );
      }
    } else {
      // No local user data, navigate to login screen
      if (mounted) {
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(builder: (context) => const LoginScreen()),
        );
      }
    }
  }

  void _initDeepLinks() {
    // Handle web initial deep link via URL query parameters
    if (kIsWeb) {
      final uri = Uri.base;
      if (uri.queryParameters.containsKey('gymId') &&
          uri.queryParameters.containsKey('equipmentId')) {
        _handleDeepLink(uri.toString());
      }
      return;
    }
    _appLinks = AppLinks();

    // Handle the very first (initial) link
    _appLinks.getInitialLink().then((uri) {
      _handleDeepLink(uri.toString());
    });

    // Now listen only to *subsequent* link events
    _appLinks.uriLinkStream
        .skip(1) // ← ignore the first event
        .listen((uri) => _handleDeepLink(uri.toString()));
  }

  void _handleDeepLink(String url) {
    final params = UrlParsingService.parseGympadUrl(url);
    if (params != null && !_isLoading) {
      _navigateToExercise(params['gymId']!, params['equipmentId']!);
    }
  }

  void _navigateToExercise(String gymId, String equipmentId) {
    final gym = _dataService.getGym(gymId);
    if (gym == null) {
      _showErrorDialog('Gym not found');
      return;
    }

    final exerciseId = _dataService.getExerciseFromEquipment(equipmentId);
    if (exerciseId == null) {
      _showErrorDialog('Exercise not found for this equipment');
      return;
    }

    final exercise = _dataService.getExercise(exerciseId);
    if (exercise == null) {
      _showErrorDialog('Exercise data not found');
      return;
    }

    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => ExerciseScreen(gym: gym, exercise: exercise),
      ),
    );
  }

  void _showErrorDialog(String message) {
    showDialog(
      context: context,
      builder:
          (context) => AlertDialog(
            title: Text('Error', style: AppTextStyles.titleMedium),
            content: Text(message, style: AppTextStyles.bodyMedium),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(),
                child: Text('OK', style: AppTextStyles.button),
              ),
            ],
          ),
    );
  }

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
                child: ElevatedButton(
                  onPressed: () {
                    Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (context) => const DevExerciseSelector(),
                      ),
                    );
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.accent,
                    foregroundColor: AppColors.primary,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: Text(
                    'DEV: Test Exercises',
                    style: AppTextStyles.button.copyWith(
                      color: AppColors.primary,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
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
