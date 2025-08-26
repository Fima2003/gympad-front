import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../services/audio_service.dart';

part 'audio_event.dart';
part 'audio_state.dart';

class AudioBloc extends Bloc<AudioEvent, AudioState> {
  final AudioService _audioService = AudioService();

  AudioBloc() : super(const AudioInitial()) {
    on<PlayTickSound>(_onPlayTick);
    on<PlayStartSound>(_onPlayStart);
  }

  Future<void> _onPlayTick(
    PlayTickSound event,
    Emitter<AudioState> emit,
  ) async {
    emit(const AudioPlaying('tick'));
    await _audioService.playTick();
    emit(const AudioInitial());
  }

  Future<void> _onPlayStart(
    PlayStartSound event,
    Emitter<AudioState> emit,
  ) async {
    emit(const AudioPlaying('start'));
    await _audioService.playStart();
    emit(const AudioInitial());
  }
}
