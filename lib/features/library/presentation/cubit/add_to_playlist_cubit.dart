import 'package:musicare_metadata_host_sdk/musicare_metadata_host_sdk.dart';
import 'package:music_are/core/cubit/safe_cubit.dart';
import 'package:music_are/core/models/section_state.dart';
import 'package:music_are/core/notice/notice_bus.dart';
import 'package:music_are/features/library/presentation/cubit/add_to_playlist_state.dart';
import 'package:music_are/features/plugin/metadata/data/repositories/library_repository.dart';
import 'package:music_are/features/plugin/metadata/data/repositories/playlist_repository.dart';
import 'package:music_are/features/plugin/shared/data/exceptions/plugin_exceptions.dart';

/// Backs the "Add to playlist" sheet: lists the user's playlists and performs
/// the add / create-and-add writes, reporting failures on the notice bus.
class AddToPlaylistCubit extends SafeCubit<AddToPlaylistState> {
  final LibraryRepository _library;
  final PlaylistRepository _playlist;
  final NoticeBus _notices;

  static const int _pageSize = 20;

  AddToPlaylistCubit(this._library, this._playlist, this._notices)
    : super(const AddToPlaylistState());

  Future<void> load() async {
    if (!_library.hasMetadata) {
      emit(
        state.copyWith(
          playlists: SectionState.error(
            PluginNotLoadedException(),
            state.playlists.data,
          ),
        ),
      );
      return;
    }

    emit(state.copyWith(playlists: SectionState.loading(state.playlists.data)));
    try {
      final result = await _library.savedPlaylists(offset: 0, limit: _pageSize);
      emit(state.copyWith(playlists: SectionState.success(result)));
    } catch (e) {
      emit(state.copyWith(playlists: SectionState.error(e, state.playlists.data)));
    }
  }

  Future<void> loadMore() async {
    final current = state.playlists;
    if (current.isLoading) return;
    if (current.data.items.length >= current.data.total) return;

    emit(state.copyWith(playlists: SectionState.loading(current.data)));
    final offset = current.data.items.length;
    try {
      final next = await _library.savedPlaylists(
        offset: offset,
        limit: _pageSize,
      );
      final combined = PaginatedResult<Playlist>(
        items: [...current.data.items, ...next.items],
        total: next.total,
        offset: offset,
        limit: _pageSize,
      );
      emit(state.copyWith(playlists: SectionState.success(combined)));
    } catch (e) {
      emit(state.copyWith(playlists: SectionState.error(e, current.data)));
    }
  }

  /// Returns whether the track was added; failures are announced on the bus.
  Future<bool> addTrack(Playlist playlist, Track track) async {
    if (state.isMutating) return false;
    emit(state.copyWith(isMutating: true));
    try {
      await _playlist.addTracks(playlist.id, [track.id]);
      return true;
    } catch (e) {
      _notices.emit(e);
      return false;
    } finally {
      emit(state.copyWith(isMutating: false));
    }
  }

  /// Creates a playlist (and adds [trackIds] when given). Returns null on
  /// failure; a partial success (created but tracks not added) is announced.
  Future<Playlist?> createPlaylist({
    required String name,
    String? description,
    bool isPublic = false,
    List<String> trackIds = const [],
  }) async {
    if (!_library.hasMetadata) return null;

    try {
      final playlist = await _playlist.createPlaylist(
        name,
        description: description,
        isPublic: isPublic,
      );
      if (playlist != null && trackIds.isNotEmpty) {
        try {
          await _playlist.addTracks(playlist.id, trackIds);
        } catch (e) {
          // The playlist exists but is empty: never leave it silent.
          _notices.emit(e);
        }
      }
      return playlist;
    } catch (e) {
      _notices.emit(e);
      return null;
    }
  }
}
