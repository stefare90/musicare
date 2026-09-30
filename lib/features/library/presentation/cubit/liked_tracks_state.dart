import 'package:musicare_metadata_host_sdk/musicare_metadata_host_sdk.dart';
import 'package:music_are/core/models/section_state.dart';

class LikedTracksState {
  final SectionState<PaginatedResult<Track>> tracks;

  const LikedTracksState({
    this.tracks = const SectionState(data: PaginatedResult<Track>.empty()),
  });

  LikedTracksState copyWith({SectionState<PaginatedResult<Track>>? tracks}) {
    return LikedTracksState(tracks: tracks ?? this.tracks);
  }
}
