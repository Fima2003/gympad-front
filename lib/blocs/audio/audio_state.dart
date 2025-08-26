part of 'audio_bloc.dart';

abstract class AudioState extends Equatable {
  const AudioState();
  @override
  List<Object?> get props => [];
}

class AudioInitial extends AudioState {
  const AudioInitial();
}

class AudioPlaying extends AudioState {
  final String soundType;
  const AudioPlaying(this.soundType);
  @override
  List<Object?> get props => [soundType];
}
