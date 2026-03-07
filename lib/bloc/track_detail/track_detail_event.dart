// lib/bloc/track_detail/track_detail_event.dart

import 'package:equatable/equatable.dart';

abstract class TrackDetailEvent extends Equatable {
  const TrackDetailEvent();
  @override
  List<Object?> get props => [];
}

class TrackDetailLoadRequested extends TrackDetailEvent {
  final int trackId;
  final String artistName;
  final String trackTitle;

  const TrackDetailLoadRequested({
    required this.trackId,
    required this.artistName,
    required this.trackTitle,
  });

  @override
  List<Object?> get props => [trackId];
}
