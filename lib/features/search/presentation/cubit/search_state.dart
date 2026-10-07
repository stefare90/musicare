import 'package:musicare_metadata_host_sdk/musicare_metadata_host_sdk.dart';
import 'package:music_are/core/models/section_state.dart';

enum SearchFilter {
  all,
  tracks,
  albums,
  artists,
  playlists;

  static SearchFilter fromCategory(SearchCategory? category) =>
      switch (category) {
        null => SearchFilter.all,
        SearchCategory.tracks => SearchFilter.tracks,
        SearchCategory.albums => SearchFilter.albums,
        SearchCategory.artists => SearchFilter.artists,
        SearchCategory.playlists => SearchFilter.playlists,
      };

  SearchCategory? get category => switch (this) {
    SearchFilter.all => null,
    SearchFilter.tracks => SearchCategory.tracks,
    SearchFilter.albums => SearchCategory.albums,
    SearchFilter.artists => SearchCategory.artists,
    SearchFilter.playlists => SearchCategory.playlists,
  };
}

class SearchState {
  final String query;
  final List<SearchCategory> chips;
  final SearchFilter filter;

  final SectionState<SearchResponse> all;
  final SectionState<PaginatedResult<Track>> tracks;
  final SectionState<PaginatedResult<Album>> albums;
  final SectionState<PaginatedResult<Artist>> artists;
  final SectionState<PaginatedResult<Playlist>> playlists;

  const SearchState({
    this.query = '',
    this.chips = const [],
    this.filter = SearchFilter.all,
    this.all = const SectionState<SearchResponse>(
      data: SearchResponse(tracks: [], albums: [], artists: [], playlists: []),
    ),
    this.tracks = const SectionState<PaginatedResult<Track>>(
      data: PaginatedResult<Track>.empty(),
    ),
    this.albums = const SectionState<PaginatedResult<Album>>(
      data: PaginatedResult<Album>.empty(),
    ),
    this.artists = const SectionState<PaginatedResult<Artist>>(
      data: PaginatedResult<Artist>.empty(),
    ),
    this.playlists = const SectionState<PaginatedResult<Playlist>>(
      data: PaginatedResult<Playlist>.empty(),
    ),
  });

  bool get isAllCategory => filter == SearchFilter.all;

  bool get isEmptyQuery => query.trim().isEmpty;

  SearchCategory? get selectedChip => filter.category;

  bool get hasResults => _activeHasData;

  bool get hasMore => switch (filter) {
    SearchFilter.all => false,
    SearchFilter.tracks => tracks.data.items.length < tracks.data.total,
    SearchFilter.albums => albums.data.items.length < albums.data.total,
    SearchFilter.artists => artists.data.items.length < artists.data.total,
    SearchFilter.playlists => playlists.data.items.length < playlists.data.total,
  };

  /// Initial loading only: no data yet.
  bool get isLoading => _activeIsLoading && !_activeHasData;

  /// A further page is being appended to already loaded data.
  bool get isLoadingMore => _activeIsLoading && _activeHasData;

  /// Initial error only; a load-more error keeps the data visible.
  Object? get error => _activeHasData ? null : _activeError;

  /// Error while appending a page, with the previous data still on screen.
  Object? get loadMoreError => _activeHasData ? _activeError : null;

  SearchResponse? get allResults => all.data;
  PaginatedResult<Track>? get trackResults => tracks.data;
  PaginatedResult<Album>? get albumResults => albums.data;
  PaginatedResult<Artist>? get artistResults => artists.data;
  PaginatedResult<Playlist>? get playlistResults => playlists.data;

  bool get _activeHasData => switch (filter) {
    SearchFilter.all => _aggregateHasContent,
    SearchFilter.tracks => tracks.data.items.isNotEmpty,
    SearchFilter.albums => albums.data.items.isNotEmpty,
    SearchFilter.artists => artists.data.items.isNotEmpty,
    SearchFilter.playlists => playlists.data.items.isNotEmpty,
  };

  SectionState<Object> get _activeSection => switch (filter) {
    SearchFilter.all => all,
    SearchFilter.tracks => tracks,
    SearchFilter.albums => albums,
    SearchFilter.artists => artists,
    SearchFilter.playlists => playlists,
  };

  bool get _activeIsLoading => _activeSection.isLoading;

  Object? get _activeError => _activeSection.error;

  bool get _aggregateHasContent =>
      all.data.tracks.isNotEmpty ||
      all.data.albums.isNotEmpty ||
      all.data.artists.isNotEmpty ||
      all.data.playlists.isNotEmpty;

  SearchState copyWith({
    String? query,
    List<SearchCategory>? chips,
    SearchFilter? filter,
    SectionState<SearchResponse>? all,
    SectionState<PaginatedResult<Track>>? tracks,
    SectionState<PaginatedResult<Album>>? albums,
    SectionState<PaginatedResult<Artist>>? artists,
    SectionState<PaginatedResult<Playlist>>? playlists,
  }) {
    return SearchState(
      query: query ?? this.query,
      chips: chips ?? this.chips,
      filter: filter ?? this.filter,
      all: all ?? this.all,
      tracks: tracks ?? this.tracks,
      albums: albums ?? this.albums,
      artists: artists ?? this.artists,
      playlists: playlists ?? this.playlists,
    );
  }
}
