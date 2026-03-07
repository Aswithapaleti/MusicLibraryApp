// lib/repositories/music_repository.dart

import '../models/track.dart';
import '../services/api_service.dart';

/// Queries used to page through a large dataset.
/// Each query can yield up to 2000 tracks (40 pages × 50 per page).
/// 26 letters + 10 digits = 36 queries → up to ~72,000 tracks.
const List<String> kSearchQueries = [
  'a', 'b', 'c', 'd', 'e', 'f', 'g', 'h', 'i', 'j',
  'k', 'l', 'm', 'n', 'o', 'p', 'q', 'r', 's', 't',
  'u', 'v', 'w', 'x', 'y', 'z',
  '0', '1', '2', '3', '4', '5', '6', '7', '8', '9',
];
const int kPageSize = 50;

class MusicRepository {
  final ApiService _api;

  MusicRepository({ApiService? apiService})
      : _api = apiService ?? ApiService();

  /// Returns next page of tracks. [queryIndex] refers to kSearchQueries index.
  /// Unwraps TracksPage → List<Track> to keep BLoC decoupled from API shape.
  Future<List<Track>> getTrackPage({
    required int queryIndex,
    required int pageIndex,
  }) async {
    if (queryIndex >= kSearchQueries.length) return [];
    final query = kSearchQueries[queryIndex];
    final page = await _api.fetchTracks(
      query: query,
      index: pageIndex * kPageSize,
      limit: kPageSize,
    );
    return page.tracks; // unwrap TracksPage → List<Track>
  }

  /// Returns a single Track used as "detail" (same model, no separate TrackDetail needed).
  Future<Track> getTrackDetail(int trackId) =>
      _api.fetchTrackDetail(trackId);

  /// Returns lyrics string or null — no Lyrics wrapper model needed.
  Future<String?> getLyrics(int trackId, String artist, String title) =>
      _api.fetchLyrics(trackId, title, artist);
}