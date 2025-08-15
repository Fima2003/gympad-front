import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/services.dart';

/// Centralized audio service to play UI sounds.
///
/// Current lightweight implementation uses SystemSound on mobile platforms
/// and is a no-op on Web. Swap internals later (e.g., audioplayers/just_audio)
/// without changing call sites.
class AudioService {
  static final AudioService _instance = AudioService._internal();
  factory AudioService() => _instance;
  AudioService._internal();

  Future<void> playTick() async {
    if (kIsWeb) return; // No-op on web for now
    // Subtle click for countdown ticks
    await SystemSound.play(SystemSoundType.click);
  }

  Future<void> playStart() async {
    if (kIsWeb) return; // No-op on web for now
    // Alert to indicate start/end events
    await SystemSound.play(SystemSoundType.alert);
  }
}
