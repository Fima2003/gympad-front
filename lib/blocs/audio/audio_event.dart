part of 'audio_bloc.dart';

abstract class AudioEvent extends Equatable {
  const AudioEvent();
  @override
  List<Object?> get props => [];
}

class PlayTickSound extends AudioEvent {}
class PlayStartSound extends AudioEvent {}
