// lib/bloc/library/library_state.dart

import 'package:equatable/equatable.dart';
import '../../models/track.dart';

enum LibraryStatus { initial, loading, success, failure }

/// A single item in the flat rendered list — either a header or a track row.
abstract class ListItem extends Equatable {
  const ListItem();
}

class HeaderItem extends ListItem {
  final String letter;
  const HeaderItem(this.letter);
  @override
  List<Object?> get props => [letter];
}

class TrackItem extends ListItem {
  final Track track;
  const TrackItem(this.track);
  @override
  List<Object?> get props => [track.id];
}

class LibraryState extends Equatable {
  final LibraryStatus status;
  final List<Track> allTracks;      // raw deduplicated store
  final List<ListItem> displayItems; // flat list: headers + tracks
  final bool hasReachedMax;
  final String searchQuery;
  final String? errorMessage;
  final bool isFetchingMore;

  // Paging cursors
  final int currentQueryIndex;
  final int currentPageIndex;

  const LibraryState({
    this.status = LibraryStatus.initial,
    this.allTracks = const [],
    this.displayItems = const [],
    this.hasReachedMax = false,
    this.searchQuery = '',
    this.errorMessage,
    this.isFetchingMore = false,
    this.currentQueryIndex = 0,
    this.currentPageIndex = 0,
  });

  bool get isSearching => searchQuery.isNotEmpty;

  LibraryState copyWith({
    LibraryStatus? status,
    List<Track>? allTracks,
    List<ListItem>? displayItems,
    bool? hasReachedMax,
    String? searchQuery,
    String? errorMessage,
    bool? isFetchingMore,
    int? currentQueryIndex,
    int? currentPageIndex,
  }) {
    return LibraryState(
      status: status ?? this.status,
      allTracks: allTracks ?? this.allTracks,
      displayItems: displayItems ?? this.displayItems,
      hasReachedMax: hasReachedMax ?? this.hasReachedMax,
      searchQuery: searchQuery ?? this.searchQuery,
      errorMessage: errorMessage,
      isFetchingMore: isFetchingMore ?? this.isFetchingMore,
      currentQueryIndex: currentQueryIndex ?? this.currentQueryIndex,
      currentPageIndex: currentPageIndex ?? this.currentPageIndex,
    );
  }

  @override
  List<Object?> get props => [
    status,
    allTracks.length,
    displayItems.length,
    hasReachedMax,
    searchQuery,
    errorMessage,
    isFetchingMore,
    currentQueryIndex,
    currentPageIndex,
  ];
}
