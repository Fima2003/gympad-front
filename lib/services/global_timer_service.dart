import 'dart:async';

class GlobalTimerService {
  static final GlobalTimerService _instance = GlobalTimerService._internal();
  factory GlobalTimerService() => _instance;
  GlobalTimerService._internal();

  Timer? _timer;
  DateTime? _startTime;
  Duration _elapsedTime = Duration.zero;
  bool _isRunning = false;

  final StreamController<Duration> _timerController =
      StreamController.broadcast();
  Stream<Duration> get timerStream => _timerController.stream;

  bool get isRunning => _isRunning;
  Duration get elapsedTime => _elapsedTime;
  DateTime? get startTime => _startTime;

  void start() {
    if (_isRunning) return;

    _startTime ??= DateTime.now();
    _isRunning = true;

    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (_startTime != null) {
        _elapsedTime = DateTime.now().difference(_startTime!);
        _timerController.add(_elapsedTime);
      }
    });
  }

  void stop() {
    if (!_isRunning) return;

    _isRunning = false;
    _timer?.cancel();
    _timer = null;
  }

  void reset() {
    stop();
    _startTime = null;
    _elapsedTime = Duration.zero;
    _timerController.add(_elapsedTime);
  }

  void dispose() {
    stop();
    _timerController.close();
  }
}
