// lib/bloc/library/library_event.dart

import 'package:equatable/equatable.dart';

abstract class LibraryEvent extends Equatable {
  const LibraryEvent();
  @override
  List<Object?> get props => [];
}

/// Initial load / refresh
class LibraryLoadRequested extends LibraryEvent {
  const LibraryLoadRequested();
}

/// User scrolled near end of visible list
class LibraryFetchNextPage extends LibraryEvent {
  const LibraryFetchNextPage();
}

/// User typed in search box
class LibrarySearchChanged extends LibraryEvent {
  final String query;
  const LibrarySearchChanged(this.query);
  @override
  List<Object?> get props => [query];
}

/// User cleared search
class LibrarySearchCleared extends LibraryEvent {
  const LibrarySearchCleared();
}
