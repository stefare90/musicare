import 'package:musicare_metadata_host_sdk/musicare_metadata_host_sdk.dart';

class SearchState {
  final String query;
  final List<SearchCategory> chips;
  final SearchCategory? selectedChip;
  final bool isLoading;
  final bool isLoadingMore;
  final Object? error;
  final Object? loadMoreError;
  final SearchResponse? allResults;

  // Paginated results for category-specific views
  final PaginatedResult<Track>? trackResults;
  final PaginatedResult<Album>? albumResults;
  final PaginatedResult<Artist>? artistResults;
  final PaginatedResult<Playlist>? playlistResults;

  const SearchState({
    this.query = '',
    this.chips = const [],
    this.selectedChip,
    this.isLoading = false,
    this.isLoadingMore = false,
    this.error,
    this.loadMoreError,
    this.allResults,
    this.trackResults,
    this.albumResults,
    this.artistResults,
    this.playlistResults,
  });

  bool get isAllCategory => selectedChip == null;

  bool get isEmptyQuery => query.trim().isEmpty;

  bool get hasResults {
    if (isAllCategory) return _aggregateHasContent;
    return _activeResults?.items.isNotEmpty ?? false;
  }

  bool get hasMore {
    final results = _activeResults;
    return results != null && results.items.length < results.total;
  }

  bool get _aggregateHasContent =>
      allResults != null &&
      (allResults!.tracks.isNotEmpty ||
          allResults!.albums.isNotEmpty ||
          allResults!.artists.isNotEmpty ||
          allResults!.playlists.isNotEmpty);

  PaginatedResult<Object>? get _activeResults {
    switch (selectedChip) {
      case SearchCategory.tracks:
        return trackResults;
      case SearchCategory.albums:
        return albumResults;
      case SearchCategory.artists:
        return artistResults;
      case SearchCategory.playlists:
        return playlistResults;
      case null:
        return null;
    }
  }

  SearchState copyWith({
    String? query,
    List<SearchCategory>? chips,
    SearchCategory? selectedChip,
    bool clearSelectedChip = false,
    bool? isLoading,
    bool? isLoadingMore,
    Object? error,
    bool clearError = false,
    Object? loadMoreError,
    bool clearLoadMoreError = false,
    SearchResponse? allResults,
    bool clearAllResults = false,
    PaginatedResult<Track>? trackResults,
    bool clearTrackResults = false,
    PaginatedResult<Album>? albumResults,
    bool clearAlbumResults = false,
    PaginatedResult<Artist>? artistResults,
    bool clearArtistResults = false,
    PaginatedResult<Playlist>? playlistResults,
    bool clearPlaylistResults = false,
  }) {
    return SearchState(
      query: query ?? this.query,
      chips: chips ?? this.chips,
      selectedChip: clearSelectedChip
          ? null
          : (selectedChip ?? this.selectedChip),
      isLoading: isLoading ?? this.isLoading,
      isLoadingMore: isLoadingMore ?? this.isLoadingMore,
      error: clearError ? null : (error ?? this.error),
      loadMoreError: clearLoadMoreError
          ? null
          : (loadMoreError ?? this.loadMoreError),
      allResults: clearAllResults ? null : (allResults ?? this.allResults),
      trackResults: clearTrackResults
          ? null
          : (trackResults ?? this.trackResults),
      albumResults: clearAlbumResults
          ? null
          : (albumResults ?? this.albumResults),
      artistResults: clearArtistResults
          ? null
          : (artistResults ?? this.artistResults),
      playlistResults: clearPlaylistResults
          ? null
          : (playlistResults ?? this.playlistResults),
    );
  }
}
