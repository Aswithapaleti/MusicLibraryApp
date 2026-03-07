import 'package:equatable/equatable.dart';

class Track extends Equatable {
  final int id;
  final String title;
  final String artistName;
  final String albumTitle;
  final String albumCover;
  final int duration;
  final String preview;
  final String? link;

  const Track({
    required this.id,
    required this.title,
    required this.artistName,
    required this.albumTitle,
    required this.albumCover,
    required this.duration,
    required this.preview,
    this.link,
  });

  factory Track.fromJson(Map<String, dynamic> json) {
    final artist = json['artist'] as Map<String, dynamic>? ?? {};
    final album = json['album'] as Map<String, dynamic>? ?? {};
    return Track(
      id: json['id'] as int? ?? 0,
      title: json['title'] as String? ?? 'Unknown Title',
      artistName: artist['name'] as String? ?? 'Unknown Artist',
      albumTitle: album['title'] as String? ?? 'Unknown Album',
      albumCover: album['cover_small'] as String? ?? '',
      duration: json['duration'] as int? ?? 0,
      preview: json['preview'] as String? ?? '',
      link: json['link'] as String?,
    );
  }

  String get groupKey {
    if (title.isEmpty) return '#';
    final first = title[0].toUpperCase();
    if (RegExp(r'[A-Z]').hasMatch(first)) return first;
    return '#';
  }

  String get durationFormatted {
    final m = duration ~/ 60;
    final s = duration % 60;
    return '${m.toString().padLeft(2, '0')}:${s.toString().padLeft(2, '0')}';
  }

  @override
  List<Object?> get props => [id, title, artistName];
}

class TrackDetail extends Equatable {
  final Track track;
  final String? lyrics;
  final bool hasLyrics;

  const TrackDetail({
    required this.track,
    this.lyrics,
    required this.hasLyrics,
  });

  @override
  List<Object?> get props => [track, lyrics];
}

class TracksPage extends Equatable {
  final List<Track> tracks;
  final String query;
  final int index;
  final bool hasMore;

  const TracksPage({
    required this.tracks,
    required this.query,
    required this.index,
    required this.hasMore,
  });

  @override
  List<Object?> get props => [tracks, query, index];
}
