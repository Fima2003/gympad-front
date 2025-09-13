import 'package:just_audio/just_audio.dart';
import 'package:gympad/services/logger_service.dart';

/// Centralized audio service to play UI sounds.
///
/// Current lightweight implementation uses SystemSound on mobile platforms
/// and is a no-op on Web. Swap internals later (e.g., audioplayers/just_audio)
/// without changing call sites.
class AudioService {
  static final AudioService _instance = AudioService._internal();
  factory AudioService() => _instance;
  AudioService._internal();

  final AudioPlayer _tickPlayer = AudioPlayer();
  final AudioPlayer _startPlayer = AudioPlayer();
  final AppLogger _logger = AppLogger();

  Future<void> playTick() async {
    // TODO: Wire actual sound once assets are finalized.
    // Keeping method to avoid breaking call sites.
    try {
      // Placeholder no-op; intentionally not playing audio yet.
    } catch (e, st) {
      _logger.error('playTick error', e, st);
    }
  }

  Future<void> playStart() async {
    try {
      // Placeholder no-op; intentionally not playing audio yet.
    } catch (e, st) {
      _logger.error('playStart error', e, st);
    }
  }

  Future<void> dispose() async {
    await _tickPlayer.dispose();
    await _startPlayer.dispose();
  }
}
