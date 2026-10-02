import 'package:musicare_metadata_host_sdk/musicare_metadata_host_sdk.dart';
import 'package:music_are/core/models/section_state.dart';

class AddToPlaylistState {
  final SectionState<PaginatedResult<Playlist>> playlists;
  final bool isMutating;

  const AddToPlaylistState({
    this.playlists = const SectionState(
      data: PaginatedResult<Playlist>.empty(),
    ),
    this.isMutating = false,
  });

  AddToPlaylistState copyWith({
    SectionState<PaginatedResult<Playlist>>? playlists,
    bool? isMutating,
  }) {
    return AddToPlaylistState(
      playlists: playlists ?? this.playlists,
      isMutating: isMutating ?? this.isMutating,
    );
  }
}
