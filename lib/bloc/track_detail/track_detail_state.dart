// lib/bloc/track_detail/track_detail_state.dart

import 'package:equatable/equatable.dart';
import '../../models/track.dart'; // Track only — no TrackDetail import

enum TrackDetailStatus {
  initial,
  loadingDetail,
  loadingLyrics,
  success,
  failure,
}

class TrackDetailState extends Equatable {
  final TrackDetailStatus status;
  final Track? detail; // was TrackDetail? — now just Track?
  final String? lyrics; // was Lyrics? — now plain String?
  final bool lyricsLoading;
  final String? errorMessage;
  final String? lyricsError;

  const TrackDetailState({
    this.status = TrackDetailStatus.initial,
    this.detail,
    this.lyrics,
    this.lyricsLoading = false,
    this.errorMessage,
    this.lyricsError,
  });

  TrackDetailState copyWith({
    TrackDetailStatus? status,
    Track? detail,
    String? lyrics,
    bool? lyricsLoading,
    String? errorMessage,
    String? lyricsError,
  }) {
    return TrackDetailState(
      status: status ?? this.status,
      detail: detail ?? this.detail,
      lyrics: lyrics ?? this.lyrics,
      lyricsLoading: lyricsLoading ?? this.lyricsLoading,
      errorMessage: errorMessage,
      lyricsError: lyricsError,
    );
  }

  @override
  List<Object?> get props => [
    status,
    detail?.id,
    lyrics,
    lyricsLoading,
    errorMessage,
    lyricsError,
  ];
}
