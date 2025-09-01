import 'package:flutter/foundation.dart';
import 'package:just_audio/just_audio.dart';
import 'package:audio_session/audio_session.dart';

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
  bool _sessionConfigured = false;

  Future<void> _setupAudioSession() async {
    if (_sessionConfigured) return;
    try {
      final session = await AudioSession.instance;
      await session.configure(AudioSessionConfiguration.music());
      _sessionConfigured = true;
    } catch (e, st) {
      debugPrint('AudioSession setup error: $e\n$st');
    }
  }

  Future<void> playTick() async {
    print("World");
    // if (kIsWeb) return;
    // await _setupAudioSession();
    // try {
    //   await _tickPlayer.setAsset('assets/sounds/tick.wav');
    //   await _tickPlayer.play();
    // } catch (e, st) {
    //   debugPrint('playTick error: $e\n$st');
    // }
  }

  Future<void> playStart() async {
    print("Hello");
    //   if (kIsWeb) return;
    //   await _setupAudioSession();
    //   try {
    //     await _startPlayer.setAsset('assets/sounds/start.wav');
    //     await _startPlayer.play();
    //   } catch (e, st) {
    // debugPrint('playStart error: $e\n$st');
    //   }
  }

  Future<void> dispose() async {
    await _tickPlayer.dispose();
    await _startPlayer.dispose();
  }
}
