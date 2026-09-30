import 'package:musicare_metadata_host_sdk/musicare_metadata_host_sdk.dart';
import 'package:music_are/core/models/section_state.dart';

/// The three account collections shown as library tabs.
enum LibrarySection { playlists, albums, artists }

class LibraryState {
  final bool isAuthenticated;
  final SectionState<PaginatedResult<Playlist>> playlists;
  final SectionState<PaginatedResult<Album>> albums;
  final SectionState<PaginatedResult<Artist>> artists;

  const LibraryState({
    this.isAuthenticated = false,
    this.playlists = const SectionState(data: PaginatedResult<Playlist>.empty()),
    this.albums = const SectionState(data: PaginatedResult<Album>.empty()),
    this.artists = const SectionState(data: PaginatedResult<Artist>.empty()),
  });

  LibraryState copyWith({
    bool? isAuthenticated,
    SectionState<PaginatedResult<Playlist>>? playlists,
    SectionState<PaginatedResult<Album>>? albums,
    SectionState<PaginatedResult<Artist>>? artists,
  }) {
    return LibraryState(
      isAuthenticated: isAuthenticated ?? this.isAuthenticated,
      playlists: playlists ?? this.playlists,
      albums: albums ?? this.albums,
      artists: artists ?? this.artists,
    );
  }
}
