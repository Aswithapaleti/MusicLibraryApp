// lib/bloc/library/library_bloc.dart

import 'dart:async';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:rxdart/rxdart.dart';
import '../../models/track.dart';
import '../../repositories/music_repository.dart';
import '../../services/api_service.dart';
import 'library_event.dart';
import 'library_state.dart';

class LibraryBloc extends Bloc<LibraryEvent, LibraryState> {
  final MusicRepository _repo;

  LibraryBloc({MusicRepository? repository})
      : _repo = repository ?? MusicRepository(),
        super(const LibraryState()) {
    on<LibraryLoadRequested>(_onLoadRequested);
    on<LibraryFetchNextPage>(
      _onFetchNextPage,
      transformer: droppable(),
    );
    on<LibrarySearchChanged>(
      _onSearchChanged,
      transformer: (events, mapper) => events
          .debounceTime(const Duration(milliseconds: 300))
          .switchMap(mapper),
    );
    on<LibrarySearchCleared>(_onSearchCleared);
  }

  // ─── Helpers ──────────────────────────────────────────────────────────────

  /// Build a flat sorted list with sticky-header items.
  List<ListItem> _buildDisplayItems(List<Track> tracks, String searchQuery) {
    List<Track> filtered = tracks;

    if (searchQuery.isNotEmpty) {
      final q = searchQuery.toLowerCase();
      filtered = tracks.where((t) {
        return t.title.toLowerCase().contains(q) ||
            t.artistName.toLowerCase().contains(q);
      }).toList();
    }

    // Sort alphabetically by title
    filtered.sort((a, b) => a.title.toLowerCase().compareTo(b.title.toLowerCase()));

    // Group into sections
    final Map<String, List<Track>> grouped = {};
    for (final track in filtered) {
      final key = track.groupKey;
      grouped.putIfAbsent(key, () => []).add(track);
    }

    // Sort section keys: A-Z then #
    final sortedKeys = grouped.keys.toList()
      ..sort((a, b) {
        if (a == '#') return 1;
        if (b == '#') return -1;
        return a.compareTo(b);
      });

    final List<ListItem> items = [];
    for (final key in sortedKeys) {
      items.add(HeaderItem(key));
      items.addAll(grouped[key]!.map((t) => TrackItem(t)));
    }
    return items;
  }

  // ─── Event Handlers ───────────────────────────────────────────────────────

  Future<void> _onLoadRequested(
      LibraryLoadRequested event,
      Emitter<LibraryState> emit,
      ) async {
    emit(const LibraryState(status: LibraryStatus.loading));
    try {
      final tracks = await _repo.getTrackPage(queryIndex: 0, pageIndex: 0);
      final displayItems = _buildDisplayItems(tracks, '');
      emit(LibraryState(
        status: LibraryStatus.success,
        allTracks: tracks,
        displayItems: displayItems,
        currentQueryIndex: 0,
        currentPageIndex: 1,
      ));
    } on ApiException catch (e) {
      emit(LibraryState(
        status: LibraryStatus.failure,
        errorMessage: e.message, // already 'NO INTERNET CONNECTION' if isNetworkError
      ));
    } catch (e) {
      emit(LibraryState(
        status: LibraryStatus.failure,
        errorMessage: e.toString(),
      ));
    }
  }

  Future<void> _onFetchNextPage(
      LibraryFetchNextPage event,
      Emitter<LibraryState> emit,
      ) async {
    if (state.hasReachedMax ||
        state.isFetchingMore ||
        state.status != LibraryStatus.success ||
        state.isSearching) return;

    emit(state.copyWith(isFetchingMore: true));

    try {
      int queryIndex = state.currentQueryIndex;
      int pageIndex = state.currentPageIndex;

      List<Track>? newTracks;

      // Try next pages / queries until we get results or exhaust all
      while (queryIndex < kSearchQueries.length) {
        final page = await _repo.getTrackPage(
          queryIndex: queryIndex,
          pageIndex: pageIndex,
        );

        if (page.isNotEmpty) {
          newTracks = page;
          pageIndex++;
          break;
        } else {
          // Exhausted this query, move to next
          queryIndex++;
          pageIndex = 0;
        }
      }

      if (newTracks == null || newTracks.isEmpty) {
        emit(state.copyWith(hasReachedMax: true, isFetchingMore: false));
        return;
      }

      // Deduplicate by id
      final existingIds = state.allTracks.map((t) => t.id).toSet();
      final unique = newTracks.where((t) => !existingIds.contains(t.id)).toList();

      final updated = [...state.allTracks, ...unique];
      final displayItems = _buildDisplayItems(updated, state.searchQuery);

      emit(state.copyWith(
        status: LibraryStatus.success,
        allTracks: updated,
        displayItems: displayItems,
        isFetchingMore: false,
        currentQueryIndex: queryIndex,
        currentPageIndex: pageIndex,
      ));
    } on ApiException catch (e) {
      emit(state.copyWith(
        isFetchingMore: false,
        errorMessage: e.message,
      ));
    } catch (e) {
      emit(state.copyWith(isFetchingMore: false));
    }
  }

  Future<void> _onSearchChanged(
      LibrarySearchChanged event,
      Emitter<LibraryState> emit,
      ) async {
    final q = event.query.trim();
    final displayItems = _buildDisplayItems(state.allTracks, q);
    emit(state.copyWith(
      searchQuery: q,
      displayItems: displayItems,
      errorMessage: null,
    ));
  }

  Future<void> _onSearchCleared(
      LibrarySearchCleared event,
      Emitter<LibraryState> emit,
      ) async {
    final displayItems = _buildDisplayItems(state.allTracks, '');
    emit(state.copyWith(
      searchQuery: '',
      displayItems: displayItems,
      errorMessage: null,
    ));
  }
}

/// Transformer: drops new events while current is being processed
EventTransformer<E> droppable<E>() {
  return (events, mapper) => events.exhaustMap(mapper);
}
