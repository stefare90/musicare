import 'package:musicare_metadata_host_sdk/musicare_metadata_host_sdk.dart';
import 'package:music_are/core/cubit/safe_cubit.dart';
import 'package:music_are/core/models/section_state.dart';
import 'package:music_are/core/notice/notice_bus.dart';
import 'package:music_are/core/utils/playlist_ownership.dart';
import 'package:music_are/features/library/presentation/cubit/add_to_playlist_state.dart';
import 'package:music_are/features/plugin/metadata/data/repositories/library_repository.dart';
import 'package:music_are/features/plugin/metadata/data/repositories/playlist_repository.dart';
import 'package:music_are/features/plugin/metadata/presentation/cubit/user_cubit.dart';
import 'package:music_are/features/plugin/shared/data/exceptions/plugin_exceptions.dart';

/// Result of the create-and-add flow: the created playlist and whether the
/// track made it in. A created playlist with `trackAdded == false` is a partial
/// success, never a failure.
class CreatePlaylistOutcome {
  final Playlist playlist;
  final bool trackAdded;

  const CreatePlaylistOutcome({
    required this.playlist,
    required this.trackAdded,
  });
}

/// Backs the "Add to playlist" sheet: lists the playlists the signed-in user can
/// write to and performs the add / create-and-add writes, reporting failures on
/// the notice bus.
///
/// Only owned playlists are listed: with the plugin saving other people's
/// playlists by reference, `savedPlaylists` also returns those, but adding a
/// track to them cannot work, so they are filtered out before being shown.
class AddToPlaylistCubit extends SafeCubit<AddToPlaylistState> {
  final LibraryRepository _library;
  final PlaylistRepository _playlist;
  final NoticeBus _notices;
  final UserSession _session;
  final UserSavedMediaIndex _savedMedia;
  final UserPlaylistEdits _edits;

  static const int _pageSize = 20;
  static const int _fetchSize = 100;

  /// The full filtered list, paginated locally so a page full of other people's
  /// playlists can never hide the owned ones.
  List<Playlist> _owned = const [];

  AddToPlaylistCubit(
    this._library,
    this._playlist,
    this._notices, {
    required this._session,
    required this._savedMedia,
    required this._edits,
  }) : super(const AddToPlaylistState());

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
    if (!_session.isAuthenticated) {
      emit(
        state.copyWith(
          playlists: SectionState.error(
            const MetadataAuthRequiredException(''),
            state.playlists.data,
          ),
        ),
      );
      return;
    }

    emit(state.copyWith(playlists: SectionState.loading(state.playlists.data)));
    try {
      _owned = await _fetchOwned();
      emit(state.copyWith(playlists: SectionState.success(_page(0))));
    } catch (e) {
      emit(
        state.copyWith(playlists: SectionState.error(e, state.playlists.data)),
      );
    }
  }

  Future<void> loadMore() async {
    final current = state.playlists;
    if (current.isLoading) return;
    if (current.data.items.length >= current.data.total) return;

    emit(state.copyWith(playlists: SectionState.loading(current.data)));
    emit(
      state.copyWith(
        playlists: SectionState.success(_page(current.data.items.length)),
      ),
    );
  }

  Future<List<Playlist>> _fetchOwned() async {
    final owned = <Playlist>[];
    var offset = 0;
    while (true) {
      final result = await _library.savedPlaylists(
        offset: offset,
        limit: _fetchSize,
      );
      owned.addAll(result.items.where((p) => p.isOwnedBy(_session.userId)));
      offset += result.items.length;
      // Guard against a provider that reports more items than it returns.
      if (result.items.isEmpty || offset >= result.total) break;
    }
    return owned;
  }

  PaginatedResult<Playlist> _page(int offset) {
    final start = offset.clamp(0, _owned.length).toInt();
    final end = (start + _pageSize).clamp(0, _owned.length).toInt();
    return PaginatedResult<Playlist>(
      items: _owned.sublist(start, end),
      total: _owned.length,
      offset: start,
      limit: _pageSize,
    );
  }

  /// Adds the track and returns the outcome (`added == 0` when the track was
  /// already there); failures are announced on the bus and return null.
  ///
  /// The write belongs to the facet (which announces failures and the change);
  /// this cubit only guards re-entrancy.
  Future<AddTracksResult?> addTrack(Playlist playlist, Track track) async {
    if (state.isMutating) return null;
    emit(state.copyWith(isMutating: true));
    try {
      return await _edits.addTrackToPlaylist(playlist.id, track.id);
    } finally {
      emit(state.copyWith(isMutating: false));
    }
  }

  /// Creates a playlist (and adds [trackIds] when given). Returns null on
  /// failure (announced on the bus); a partial success (created but tracks not
  /// added) is a non-null outcome with `trackAdded == false`.
  Future<CreatePlaylistOutcome?> createPlaylist({
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
      if (playlist == null) return null;

      var trackAdded = true;
      if (trackIds.isNotEmpty) {
        try {
          final result = await _playlist.addTracks(playlist.id, trackIds);
          // A brand new playlist cannot already hold them, but a duplicate in
          // the batch is still reported as not added.
          trackAdded = result.added > 0;
        } catch (_) {
          // The playlist exists but is empty: surfaced as a partial success by
          // the caller, never left silent.
          trackAdded = false;
        }
      }
      // A new playlist lands in the saved set: announce it through `changes` so
      // the Library's Playlists tab reloads on its own.
      await _savedMedia.refresh(MediaItemType.playlist);
      return CreatePlaylistOutcome(playlist: playlist, trackAdded: trackAdded);
    } catch (e) {
      _notices.emit(Notice.error(e));
      return null;
    }
  }
}
