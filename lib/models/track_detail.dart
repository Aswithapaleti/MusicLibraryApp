// lib/models/track_detail.dart

class TrackDetail {
  final int id;
  final String title;
  final String artistName;
  final String? artistPictureMedium;
  final String? albumTitle;
  final String? albumCoverMedium;
  final int? duration;
  final String? preview;
  final int? rank;
  final int? bpm;
  final double? gain;
  final List<String> genres;

  const TrackDetail({
    required this.id,
    required this.title,
    required this.artistName,
    this.artistPictureMedium,
    this.albumTitle,
    this.albumCoverMedium,
    this.duration,
    this.preview,
    this.rank,
    this.bpm,
    this.gain,
    this.genres = const [],
  });

  factory TrackDetail.fromJson(Map<String, dynamic> json) {
    final artist = json['artist'] as Map<String, dynamic>?;
    final album = json['album'] as Map<String, dynamic>?;
    final genresList = (album?['genres']?['data'] as List<dynamic>?)
        ?.map((g) => (g['name'] as String?) ?? '')
        .where((g) => g.isNotEmpty)
        .toList() ??
        [];

    return TrackDetail(
      id: json['id'] as int,
      title: (json['title'] as String?) ?? 'Unknown Title',
      artistName: (artist?['name'] as String?) ?? 'Unknown Artist',
      artistPictureMedium: artist?['picture_medium'] as String?,
      albumTitle: album?['title'] as String?,
      albumCoverMedium: album?['cover_medium'] as String?,
      duration: json['duration'] as int?,
      preview: json['preview'] as String?,
      rank: json['rank'] as int?,
      bpm: json['bpm'] != null ? (json['bpm'] as num).toInt() : null,
      gain: json['gain'] != null ? (json['gain'] as num).toDouble() : null,
      genres: genresList,
    );
  }

  String get durationFormatted {
    if (duration == null) return '--:--';
    final m = duration! ~/ 60;
    final s = duration! % 60;
    return '${m.toString().padLeft(2, '0')}:${s.toString().padLeft(2, '0')}';
  }
}

class Lyrics {
  final int trackId;
  final String? text;
  final String? syncedLyrics;

  const Lyrics({
    required this.trackId,
    this.text,
    this.syncedLyrics,
  });

  bool get hasLyrics => (text != null && text!.isNotEmpty);

  factory Lyrics.fromJson(Map<String, dynamic> json) {
    return Lyrics(
      trackId: json['track_id'] as int? ?? 0,
      text: json['lyrics_text'] as String?,
      syncedLyrics: json['lyrics_sync_json'] as String?,
    );
  }

  factory Lyrics.notFound(int trackId) {
    return Lyrics(trackId: trackId, text: null);
  }
}
