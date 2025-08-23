import 'package:logging/logging.dart';

/// Centralized logging service for the application
class AppLogger {
  static final AppLogger _instance = AppLogger._internal();
  factory AppLogger() => _instance;
  AppLogger._internal();

  late final Logger _logger;

  static const String _loggerName = 'GymPad';

  /// Initialize the logger with the specified level
  void initialize({Level level = Level.INFO}) {
    // Enable hierarchical logging
    hierarchicalLoggingEnabled = true;

    _logger = Logger(_loggerName);
    _logger.level = level;

    // Set up console logging
    Logger.root.level = level;
    Logger.root.onRecord.listen((record) {
      final time = record.time.toIso8601String();
      final level = record.level.name.padRight(7);
      final loggerName = record.loggerName.padRight(10);
      final message = record.message;

      print('[$time] [$level] [$loggerName] $message');

      if (record.error != null) {
        print('  Error: ${record.error}');
      }

      if (record.stackTrace != null) {
        print('  Stack trace: ${record.stackTrace}');
      }
    });
  }

  /// Log debug message
  void debug(String message, [Object? error, StackTrace? stackTrace]) {
    _logger.fine(message, error, stackTrace);
  }

  /// Log info message
  void info(String message, [Object? error, StackTrace? stackTrace]) {
    _logger.info(message, error, stackTrace);
  }

  /// Log warning message
  void warning(String message, [Object? error, StackTrace? stackTrace]) {
    _logger.warning(message, error, stackTrace);
  }

  /// Log error message
  void error(String message, [Object? error, StackTrace? stackTrace]) {
    _logger.severe(message, error, stackTrace);
  }

  /// Log config message
  void config(String message, [Object? error, StackTrace? stackTrace]) {
    _logger.config(message, error, stackTrace);
  }

  /// Create a child logger for specific components
  Logger createLogger(String name) {
    hierarchicalLoggingEnabled = true;
    return Logger('$_loggerName.$name');
  }

  /// Set logging level dynamically
  void setLevel(Level level) {
    _logger.level = level;
    Logger.root.level = level;
  }

  /// Get current logging level
  Level get level => _logger.level;
}
