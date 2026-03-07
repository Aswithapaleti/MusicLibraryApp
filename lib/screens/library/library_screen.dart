// lib/screens/library/library_screen.dart

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../bloc/library/library_bloc.dart';
import '../../bloc/library/library_event.dart';
import '../../bloc/library/library_state.dart';
import '../../models/track.dart';
import '../../widgets/track_list_item.dart';
import '../track_detail/track_detail_screen.dart';

class LibraryScreen extends StatefulWidget {
  const LibraryScreen({super.key});

  @override
  State<LibraryScreen> createState() => _LibraryScreenState();
}

class _LibraryScreenState extends State<LibraryScreen> {
  late final ScrollController _scrollController;
  late final TextEditingController _searchController;

  @override
  void initState() {
    super.initState();
    _scrollController = ScrollController();
    _searchController = TextEditingController();
    _scrollController.addListener(_onScroll);
    context.read<LibraryBloc>().add(const LibraryLoadRequested());
  }

  void _onScroll() {
    if (!_scrollController.hasClients) return;
    final maxScroll = _scrollController.position.maxScrollExtent;
    final current = _scrollController.position.pixels;
    // Trigger fetch when within 300px of end
    if (current >= maxScroll - 300) {
      context.read<LibraryBloc>().add(const LibraryFetchNextPage());
    }
  }

  @override
  void dispose() {
    _scrollController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Music Library'),
        centerTitle: false,
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(60),
          child: _SearchBar(controller: _searchController),
        ),
      ),
      body: BlocBuilder<LibraryBloc, LibraryState>(
        builder: (context, state) {
          if (state.status == LibraryStatus.loading) {
            return const Center(child: CircularProgressIndicator());
          }

          if (state.status == LibraryStatus.failure &&
              state.allTracks.isEmpty) {
            return _ErrorView(
              message: state.errorMessage ?? 'Something went wrong',
              onRetry: () =>
                  context.read<LibraryBloc>().add(const LibraryLoadRequested()),
            );
          }

          if (state.displayItems.isEmpty) {
            return Center(
              child: state.isSearching
                  ? const Text('No tracks match your search.')
                  : const Text('No tracks loaded yet.'),
            );
          }

          return Column(
            children: [
              _TrackCountBanner(
                total: state.allTracks.length,
                filtered: state.displayItems
                    .whereType<TrackItem>()
                    .length,
                isSearching: state.isSearching,
              ),
              if (state.errorMessage != null)
                _InlineBanner(message: state.errorMessage!),
              Expanded(
                child: _VirtualList(
                  state: state,
                  scrollController: _scrollController,
                ),
              ),
              if (state.isFetchingMore)
                const Padding(
                  padding: EdgeInsets.all(12),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      ),
                      SizedBox(width: 12),
                      Text('Loading more tracks…'),
                    ],
                  ),
                ),
              if (state.hasReachedMax && !state.isSearching)
                Padding(
                  padding: const EdgeInsets.all(12),
                  child: Text(
                    '✓ All ${state.allTracks.length} tracks loaded',
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                ),
            ],
          );
        },
      ),
    );
  }
}

// ─── Sub-widgets ────────────────────────────────────────────────────────────

class _SearchBar extends StatelessWidget {
  final TextEditingController controller;
  const _SearchBar({required this.controller});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(12, 0, 12, 8),
      child: TextField(
        controller: controller,
        decoration: InputDecoration(
          hintText: 'Search tracks or artists…',
          prefixIcon: const Icon(Icons.search),
          suffixIcon: controller.text.isNotEmpty
              ? IconButton(
            icon: const Icon(Icons.clear),
            onPressed: () {
              controller.clear();
              context
                  .read<LibraryBloc>()
                  .add(const LibrarySearchCleared());
            },
          )
              : null,
          filled: true,
          isDense: true,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(10),
            borderSide: BorderSide.none,
          ),
        ),
        onChanged: (val) {
          context.read<LibraryBloc>().add(LibrarySearchChanged(val));
        },
      ),
    );
  }
}

class _VirtualList extends StatelessWidget {
  final LibraryState state;
  final ScrollController scrollController;

  const _VirtualList({
    required this.state,
    required this.scrollController,
  });

  @override
  Widget build(BuildContext context) {
    final items = state.displayItems;

    return ListView.builder(
      controller: scrollController,
      // addAutomaticKeepAlives: false — crucial for memory
      addAutomaticKeepAlives: false,
      addRepaintBoundaries: true,
      itemCount: items.length,
      // Provide fixed extents for homogeneous lists: headers=42, tracks=72
      itemBuilder: (context, index) {
        final item = items[index];
        if (item is HeaderItem) {
          return SectionHeader(letter: item.letter);
        }
        if (item is TrackItem) {
          return TrackListItem(
            track: item.track,
            onTap: () => _openDetail(context, item.track),
          );
        }
        return const SizedBox.shrink();
      },
    );
  }

  void _openDetail(BuildContext context, Track track) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => TrackDetailScreen(
          trackId: track.id,
          artistName: track.artistName,
          trackTitle: track.title,
            albumCover: track.albumCover,
        ),
      ),
    );
  }
}

class _TrackCountBanner extends StatelessWidget {
  final int total;
  final int filtered;
  final bool isSearching;

  const _TrackCountBanner({
    required this.total,
    required this.filtered,
    required this.isSearching,
  });

  @override
  Widget build(BuildContext context) {
    final label = isSearching
        ? '$filtered results (of $total loaded)'
        : '$total tracks loaded';
    return Container(
      width: double.infinity,
      color: Theme.of(context).colorScheme.surfaceVariant,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      child: Text(label, style: Theme.of(context).textTheme.labelSmall),
    );
  }
}

class _InlineBanner extends StatelessWidget {
  final String message;
  const _InlineBanner({required this.message});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      color: Colors.red.shade700,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      child: Text(
        message,
        style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
      ),
    );
  }
}

class _ErrorView extends StatelessWidget {
  final String message;
  final VoidCallback onRetry;

  const _ErrorView({required this.message, required this.onRetry});

  @override
  Widget build(BuildContext context) {
    final isNoInternet = message.contains('NO INTERNET');
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              isNoInternet ? Icons.wifi_off : Icons.error_outline,
              size: 64,
              color: Colors.red.shade400,
            ),
            const SizedBox(height: 16),
            Text(
              message,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Colors.red.shade400,
              ),
            ),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: onRetry,
              icon: const Icon(Icons.refresh),
              label: const Text('Retry'),
            ),
          ],
        ),
      ),
    );
  }
}
