import 'package:musicare_metadata_host_sdk/musicare_metadata_host_sdk.dart';
import 'package:music_are/core/models/media_item_metadata.dart';
import 'package:music_are/core/models/section_state.dart';

class ArtistState {
  final Artist artist;
  final SectionState<PaginatedResult<Track>> topTracks;
  final SectionState<PaginatedResult<Album>> albums;
  final SectionState<PaginatedResult<Artist>> related;

  const ArtistState({
    required this.artist,
    this.topTracks = const SectionState(
      data: PaginatedResult<Track>.empty(),
      isLoading: true,
    ),
    this.albums = const SectionState(
      data: PaginatedResult<Album>.empty(),
      isLoading: true,
    ),
    this.related = const SectionState(
      data: PaginatedResult<Artist>.empty(),
      isLoading: true,
    ),
  });

  MediaItemMetadata get metadata => MediaItemMetadata.from(artist);

  bool get isAnySectionLoading =>
      topTracks.isLoading || albums.isLoading || related.isLoading;

  bool get hasAnyDataLoaded =>
      topTracks.data.items.isNotEmpty ||
      albums.data.items.isNotEmpty ||
      related.data.items.isNotEmpty;

  bool get isTotalFailure =>
      !isAnySectionLoading &&
      !hasAnyDataLoaded &&
      (topTracks.hasError && albums.hasError && related.hasError);

  Object? get firstError => topTracks.error ?? albums.error ?? related.error;

  ArtistState copyWith({
    Artist? artist,
    SectionState<PaginatedResult<Track>>? topTracks,
    SectionState<PaginatedResult<Album>>? albums,
    SectionState<PaginatedResult<Artist>>? related,
  }) {
    return ArtistState(
      artist: artist ?? this.artist,
      topTracks: topTracks ?? this.topTracks,
      albums: albums ?? this.albums,
      related: related ?? this.related,
    );
  }
}
