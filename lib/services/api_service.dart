// lib/services/api_service.dart

import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import '../models/track.dart';

class ApiException implements Exception {
  final String message;
  final bool isNetworkError;
  const ApiException(this.message, {this.isNetworkError = false});
  @override
  String toString() => message;
}

class ApiService {
  static const String _baseUrl = 'http://5.78.43.182:5050';
  static const String _deezerUrl = 'https://api.deezer.com';
  static const Duration _timeout = Duration(seconds: 15);

  final http.Client _client;
  ApiService({http.Client? client}) : _client = client ?? http.Client();

  Future<TracksPage> fetchTracks({
    String query = 'a',
    int index = 0,
    int limit = 50,
  }) async {
    try {
      final uri = Uri.parse(
        '$_baseUrl/tracks?q=${Uri.encodeComponent(query)}&index=$index&limit=$limit',
      );
      final response = await _client.get(uri).timeout(_timeout);

      if (response.statusCode == 200) {
        final data = json.decode(response.body) as Map<String, dynamic>;
        final rawTracks = data['tracks'] as List<dynamic>? ?? [];
        final tracks = rawTracks
            .map((e) => Track.fromJson(e as Map<String, dynamic>))
            .toList();
        final hasMore = tracks.length >= limit;
        return TracksPage(
          tracks: tracks,
          query: query,
          index: index,
          hasMore: hasMore,
        );
      } else {
        throw ApiException('Server error: ${response.statusCode}');
      }
    } on SocketException {
      throw const ApiException('NO INTERNET CONNECTION', isNetworkError: true);
    } on HttpException {
      throw const ApiException('NO INTERNET CONNECTION', isNetworkError: true);
    } on ApiException {
      rethrow;
    } catch (e) {
      if (e.toString().contains('SocketException') ||
          e.toString().contains('Connection')) {
        throw const ApiException('NO INTERNET CONNECTION', isNetworkError: true);
      }
      throw ApiException('Failed to load tracks: $e');
    }
  }

  /// Fetches track detail directly from Deezer by numeric track ID.
  /// e.g. GET https://api.deezer.com/track/3135556
  Future<Track> fetchTrackDetail(int trackId) async {
    try {
      final uri = Uri.parse('$_deezerUrl/track/$trackId');
      final response = await _client.get(uri).timeout(_timeout);

      if (response.statusCode == 200) {
        final data = json.decode(response.body) as Map<String, dynamic>;

        // Deezer returns {"error": {...}} for invalid IDs
        if (data.containsKey('error')) {
          final errorMsg = data['error']['message'] as String? ?? 'Track not found';
          throw ApiException(errorMsg);
        }

        return Track.fromJson(data);
      } else {
        throw ApiException('Server error: ${response.statusCode}');
      }
    } on SocketException {
      throw const ApiException('NO INTERNET CONNECTION', isNetworkError: true);
    } on ApiException {
      rethrow;
    } catch (e) {
      if (e.toString().contains('SocketException')) {
        throw const ApiException('NO INTERNET CONNECTION', isNetworkError: true);
      }
      throw ApiException('Failed to load track details: $e');
    }
  }

  // Lyrics via lyrics.ovh — free, no API key needed
  Future<String?> fetchLyrics(int trackId, String trackTitle, String artistName) async {
    try {
      final encodedArtist = Uri.encodeComponent(artistName);
      final encodedTitle = Uri.encodeComponent(trackTitle);
      final uri = Uri.parse('https://api.lyrics.ovh/v1/$encodedArtist/$encodedTitle');
      final response = await _client.get(uri).timeout(_timeout);

      if (response.statusCode == 200) {
        final data = json.decode(response.body) as Map<String, dynamic>;
        final lyrics = data['lyrics'] as String?;
        return (lyrics != null && lyrics.trim().isNotEmpty) ? lyrics : null;
      }
      return null;
    } on SocketException {
      throw const ApiException('NO INTERNET CONNECTION', isNetworkError: true);
    } catch (e) {
      return null; // Lyrics not critical — fail silently
    }
  }
}