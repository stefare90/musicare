import 'package:gyawun_metadata_sdk/metadata/models/album.dart';
import 'package:gyawun_metadata_sdk/metadata/models/artist.dart';
import 'package:gyawun_metadata_sdk/metadata/models/pagination.dart';
import 'package:gyawun_metadata_sdk/metadata/models/playlist.dart';
import 'package:gyawun_metadata_sdk/metadata/models/search.dart';
import 'package:gyawun_metadata_sdk/metadata/models/track.dart';

enum SearchCategory { all, tracks, albums, artists, playlists }

class SearchState {
  final String query;
  final List<String> chips;
  final String? selectedChip; // null or 'all' represents SearchCategory.all
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

  bool get isAllCategory =>
      selectedChip == null ||
      selectedChip!.isEmpty ||
      selectedChip!.toLowerCase() == 'all';

  bool get isEmptyQuery => query.trim().isEmpty;

  bool get hasResults {
    if (isAllCategory) {
      if (allResults == null) return false;
      return allResults!.tracks.isNotEmpty ||
          allResults!.albums.isNotEmpty ||
          allResults!.artists.isNotEmpty ||
          allResults!.playlists.isNotEmpty;
    }

    final category = resolvedCategory;
    switch (category) {
      case SearchCategory.tracks:
        return (trackResults?.items.isNotEmpty ?? false);
      case SearchCategory.albums:
        return (albumResults?.items.isNotEmpty ?? false);
      case SearchCategory.artists:
        return (artistResults?.items.isNotEmpty ?? false);
      case SearchCategory.playlists:
        return (playlistResults?.items.isNotEmpty ?? false);
      case SearchCategory.all:
        return allResults != null &&
            (allResults!.tracks.isNotEmpty ||
                allResults!.albums.isNotEmpty ||
                allResults!.artists.isNotEmpty ||
                allResults!.playlists.isNotEmpty);
    }
  }

  SearchCategory get resolvedCategory {
    if (selectedChip == null || selectedChip!.isEmpty) {
      return SearchCategory.all;
    }
    final normalized = selectedChip!.trim().toLowerCase();
    if (normalized == 'tracks' || normalized == 'songs' || normalized == 'song' || normalized == 'track') {
      return SearchCategory.tracks;
    }
    if (normalized == 'albums' || normalized == 'album') {
      return SearchCategory.albums;
    }
    if (normalized == 'artists' || normalized == 'artist') {
      return SearchCategory.artists;
    }
    if (normalized == 'playlists' || normalized == 'playlist') {
      return SearchCategory.playlists;
    }
    return SearchCategory.all;
  }

  bool get hasMore {
    if (isAllCategory) return false;
    final category = resolvedCategory;
    switch (category) {
      case SearchCategory.tracks:
        if (trackResults == null) return false;
        return trackResults!.items.length < trackResults!.total;
      case SearchCategory.albums:
        if (albumResults == null) return false;
        return albumResults!.items.length < albumResults!.total;
      case SearchCategory.artists:
        if (artistResults == null) return false;
        return artistResults!.items.length < artistResults!.total;
      case SearchCategory.playlists:
        if (playlistResults == null) return false;
        return playlistResults!.items.length < playlistResults!.total;
      case SearchCategory.all:
        return false;
    }
  }

  SearchState copyWith({
    String? query,
    List<String>? chips,
    String? selectedChip,
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
      selectedChip:
          clearSelectedChip ? null : (selectedChip ?? this.selectedChip),
      isLoading: isLoading ?? this.isLoading,
      isLoadingMore: isLoadingMore ?? this.isLoadingMore,
      error: clearError ? null : (error ?? this.error),
      loadMoreError:
          clearLoadMoreError ? null : (loadMoreError ?? this.loadMoreError),
      allResults:
          clearAllResults ? null : (allResults ?? this.allResults),
      trackResults:
          clearTrackResults ? null : (trackResults ?? this.trackResults),
      albumResults:
          clearAlbumResults ? null : (albumResults ?? this.albumResults),
      artistResults:
          clearArtistResults ? null : (artistResults ?? this.artistResults),
      playlistResults:
          clearPlaylistResults ? null : (playlistResults ?? this.playlistResults),
    );
  }
}
