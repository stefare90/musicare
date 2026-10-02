import 'package:musicare_metadata_host_sdk/musicare_metadata_host_sdk.dart';
import 'package:music_are/core/cubit/safe_cubit.dart';
import 'package:music_are/core/models/section_state.dart';
import 'package:music_are/core/notice/notice_bus.dart';
import 'package:music_are/features/library/presentation/cubit/liked_tracks_state.dart';
import 'package:music_are/features/plugin/metadata/data/repositories/library_repository.dart';
import 'package:music_are/features/plugin/shared/data/exceptions/plugin_exceptions.dart';
import 'package:music_are/features/plugin/shared/presentation/utils/notice.dart';

/// The signed-in user's liked tracks, paginated.
///
/// Liked tracks are provider feedback, not a playlist, so they get their own
/// screen reached from the pinned *Liked Songs* entry.
class LikedTracksCubit extends SafeCubit<LikedTracksState> {
  final LibraryRepository _library;
  final NoticeBus _notices;

  static const int _pageSize = 20;

  LikedTracksCubit(this._library, this._notices)
    : super(const LikedTracksState());

  Future<void> load() async {
    if (!_library.hasMetadata) {
      emit(
        LikedTracksState(
          tracks: SectionState.error(
            PluginNotLoadedException(),
            state.tracks.data,
          ),
        ),
      );
      return;
    }

    emit(state.copyWith(tracks: SectionState.loading(state.tracks.data)));
    try {
      final result = await _library.savedTracks(
        offset: 0,
        limit: _pageSize,
      );
      emit(state.copyWith(tracks: SectionState.success(result)));
    } catch (e) {
      emit(state.copyWith(tracks: SectionState.error(e, state.tracks.data)));
      if (e.needsNotice) _notices.emit(e);
    }
  }

  Future<void> loadMore() async {
    final current = state.tracks;
    if (current.isLoading) return;
    if (current.data.items.length >= current.data.total) return;

    emit(state.copyWith(tracks: SectionState.loading(current.data)));
    final offset = current.data.items.length;
    try {
      final next = await _library.savedTracks(
        offset: offset,
        limit: _pageSize,
      );
      final combined = PaginatedResult<Track>(
        items: [...current.data.items, ...next.items],
        total: next.total,
        offset: offset,
        limit: _pageSize,
      );
      emit(state.copyWith(tracks: SectionState.success(combined)));
    } catch (e) {
      emit(state.copyWith(tracks: SectionState.error(e, current.data)));
      if (e.needsNotice) _notices.emit(e);
    }
  }
}
