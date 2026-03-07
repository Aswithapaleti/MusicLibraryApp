// lib/bloc/track_detail/track_detail_bloc.dart

import 'package:flutter_bloc/flutter_bloc.dart';
import '../../models/track.dart';
import '../../repositories/music_repository.dart';
import '../../services/api_service.dart';
import 'track_detail_event.dart';
import 'track_detail_state.dart';

class TrackDetailBloc extends Bloc<TrackDetailEvent, TrackDetailState> {
  final MusicRepository _repo;

  TrackDetailBloc({MusicRepository? repository})
      : _repo = repository ?? MusicRepository(),
        super(const TrackDetailState()) {
    on<TrackDetailLoadRequested>(_onLoadRequested);
  }

  Future<void> _onLoadRequested(
      TrackDetailLoadRequested event,
      Emitter<TrackDetailState> emit,
      ) async {
    emit(const TrackDetailState(status: TrackDetailStatus.loadingDetail));

    try {
      // 1. Fetch track detail
      final Track detail = await _repo.getTrackDetail(event.trackId);

      emit(TrackDetailState(
        status: TrackDetailStatus.loadingLyrics,
        detail: detail,
        lyricsLoading: true,
      ));

      // 2. Fetch lyrics — failure here should NOT hide the detail
      try {
        final String? lyrics = await _repo.getLyrics(
          event.trackId,
          event.artistName,
          event.trackTitle,
        );
        emit(TrackDetailState(
          status: TrackDetailStatus.success,
          detail: detail,
          lyrics: lyrics,         // may be null — UI handles that
          lyricsLoading: false,
        ));
      } on ApiException catch (e) {
        // Network error on lyrics fetch — still show detail
        emit(TrackDetailState(
          status: TrackDetailStatus.success,
          detail: detail,
          lyricsLoading: false,
          lyricsError: e.message, // 'NO INTERNET CONNECTION' if network error
        ));
      } catch (_) {
        emit(TrackDetailState(
          status: TrackDetailStatus.success,
          detail: detail,
          lyricsLoading: false,
          lyricsError: 'Lyrics not available',
        ));
      }
    } on ApiException catch (e) {
      // Network/server error on detail fetch — full failure
      emit(TrackDetailState(
        status: TrackDetailStatus.failure,
        errorMessage: e.message,
      ));
    } catch (e) {
      emit(TrackDetailState(
        status: TrackDetailStatus.failure,
        errorMessage: e.toString(),
      ));
    }
  }
}