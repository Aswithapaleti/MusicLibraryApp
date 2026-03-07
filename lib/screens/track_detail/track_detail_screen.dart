// lib/screens/track_detail/track_detail_screen.dart

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../../bloc/track_detail/track_detail_bloc.dart';
import '../../bloc/track_detail/track_detail_event.dart';
import '../../bloc/track_detail/track_detail_state.dart';
import '../../repositories/music_repository.dart';

class TrackDetailScreen extends StatelessWidget {
  final int trackId;
  final String artistName;
  final String trackTitle;
  final String? albumCover;

  const TrackDetailScreen({
    super.key,
    required this.trackId,
    required this.artistName,
    required this.trackTitle,
    this.albumCover,
  });

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => TrackDetailBloc(repository: MusicRepository())
        ..add(
          TrackDetailLoadRequested(
            trackId: trackId,
            artistName: artistName,
            trackTitle: trackTitle,
          ),
        ),
      child: _TrackDetailView(
        trackId: trackId,
        artistName: artistName,
        trackTitle: trackTitle,
        albumCover: albumCover,
      ),
    );
  }
}

class _TrackDetailView extends StatelessWidget {
  final int trackId;
  final String artistName;
  final String trackTitle;
  final String? albumCover;

  const _TrackDetailView({
    required this.trackId,
    required this.artistName,
    required this.trackTitle,
    this.albumCover,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: BlocBuilder<TrackDetailBloc, TrackDetailState>(
        builder: (context, state) {
          return switch (state.status) {
            TrackDetailStatus.initial ||
            TrackDetailStatus.loadingDetail => _LoadingView(
              title: trackTitle,
              artist: artistName,
              cover: albumCover,
            ),
            TrackDetailStatus.failure => _FailureView(
              message: state.errorMessage ?? 'Unknown error',
              onRetry: () => context.read<TrackDetailBloc>().add(
                TrackDetailLoadRequested(
                  trackId: trackId,
                  artistName: artistName,
                  trackTitle: trackTitle,
                ),
              ),
            ),
            _ => _SuccessView(state: state),
          };
        },
      ),
    );
  }
}

// ─── Loading ──────────────────────────────────────────────────────────────

class _LoadingView extends StatelessWidget {
  final String title;
  final String artist;
  final String? cover;

  const _LoadingView({required this.title, required this.artist, this.cover});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(title)),
      body: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (cover != null && cover!.isNotEmpty)
              CachedNetworkImage(
                imageUrl: cover!,
                width: 120,
                height: 120,
                fit: BoxFit.cover,
              ),
            const SizedBox(height: 24),
            const CircularProgressIndicator(),
            const SizedBox(height: 16),
            Text('Loading details for\n$title', textAlign: TextAlign.center),
          ],
        ),
      ),
    );
  }
}

// ─── Failure ──────────────────────────────────────────────────────────────

class _FailureView extends StatelessWidget {
  final String message;
  final VoidCallback onRetry;

  const _FailureView({required this.message, required this.onRetry});

  @override
  Widget build(BuildContext context) {
    final isNoInternet = message.contains('NO INTERNET');
    return Scaffold(
      appBar: AppBar(title: const Text('Track Details')),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                isNoInternet ? Icons.wifi_off : Icons.error_outline,
                size: 72,
                color: Colors.red.shade400,
              ),
              const SizedBox(height: 20),
              Text(
                message,
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: Colors.red.shade400,
                ),
              ),
              const SizedBox(height: 28),
              ElevatedButton.icon(
                onPressed: onRetry,
                icon: const Icon(Icons.refresh),
                label: const Text('Retry'),
              ),
              const SizedBox(height: 12),
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Go Back'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ─── Success ──────────────────────────────────────────────────────────────

class _SuccessView extends StatelessWidget {
  final TrackDetailState state;

  const _SuccessView({required this.state});

  @override
  Widget build(BuildContext context) {
    final detail = state.detail!; // Track

    return Scaffold(
      body: CustomScrollView(
        slivers: [
          SliverAppBar(
            expandedHeight: 260,
            pinned: true,
            flexibleSpace: FlexibleSpaceBar(
              title: Text(
                detail.title,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              background: Stack(
                fit: StackFit.expand,
                children: [
                  if (detail.albumCover.isNotEmpty) // ✅ non-nullable String
                    CachedNetworkImage(
                      imageUrl: detail.albumCover,
                      fit: BoxFit.cover,
                    )
                  else
                    Container(color: Colors.grey.shade900),
                  const DecoratedBox(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [Colors.transparent, Colors.black87],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      CircleAvatar(
                        backgroundColor: Theme.of(context).colorScheme.primary,
                        radius: 24,
                        child: Text(
                          detail.artistName.isNotEmpty
                              ? detail.artistName[0].toUpperCase()
                              : '?',
                          style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              detail.artistName,
                              style: Theme.of(context).textTheme.titleMedium,
                            ),
                            if (detail
                                .albumTitle
                                .isNotEmpty) // ✅ non-nullable String
                              Text(
                                detail.albumTitle,
                                style: Theme.of(context).textTheme.bodySmall,
                              ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),

                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      _StatChip(
                        label: 'Duration',
                        value: detail
                            .durationFormatted, // ✅ getter exists on Track
                      ),
                      _StatChip(label: 'ID', value: '${detail.id}'),
                      // ✅ rank/bpm removed — not on Track
                    ],
                  ),
                  const SizedBox(height: 20),

                  const Divider(),
                  const SizedBox(height: 12),

                  Text(
                    'Lyrics',
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                  const SizedBox(height: 12),
                  _LyricsSection(state: state),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _StatChip extends StatelessWidget {
  final String label;
  final String value;

  const _StatChip({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surfaceVariant,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        children: [
          Text(
            label,
            style: Theme.of(
              context,
            ).textTheme.labelSmall?.copyWith(color: Colors.grey),
          ),
          Text(value, style: Theme.of(context).textTheme.titleSmall),
        ],
      ),
    );
  }
}

class _LyricsSection extends StatelessWidget {
  final TrackDetailState state;

  const _LyricsSection({required this.state});

  @override
  Widget build(BuildContext context) {
    if (state.lyricsLoading) {
      return const Row(
        children: [
          SizedBox(
            width: 18,
            height: 18,
            child: CircularProgressIndicator(strokeWidth: 2),
          ),
          SizedBox(width: 12),
          Text('Fetching lyrics…'),
        ],
      );
    }

    if (state.lyricsError != null) {
      final isNoInternet = state.lyricsError!.contains('NO INTERNET');
      return Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Colors.red.shade900.withOpacity(0.3),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: Colors.red.shade700),
        ),
        child: Row(
          children: [
            Icon(
              isNoInternet ? Icons.wifi_off : Icons.info_outline,
              color: Colors.red.shade400,
              size: 20,
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                state.lyricsError!,
                style: TextStyle(color: Colors.red.shade300),
              ),
            ),
          ],
        ),
      );
    }

    if (state.lyrics == null || state.lyrics!.trim().isEmpty) {
      return const Padding(
        padding: EdgeInsets.symmetric(vertical: 8),
        child: Text(
          'No lyrics available for this track.',
          style: TextStyle(color: Colors.grey),
        ),
      );
    }

    return SelectableText(
      state.lyrics!, // ✅ plain String, no .text needed
      style: const TextStyle(height: 1.7, fontSize: 15),
    );
  }
}
