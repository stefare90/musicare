import 'dart:async';

import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:musicare_metadata_host_sdk/musicare_metadata_host_sdk.dart';
import 'package:music_are/features/plugin/metadata/presentation/cubit/user_cubit.dart';
import 'package:music_are/features/plugin/shared/data/models/plugin_manifest.dart';

PluginManifest testPluginManifest({String name = 'Test Provider'}) =>
    PluginManifest(
      id: 'test.plugin',
      packageId: 'test_plugin',
      type: 'metadata',
      name: name,
      version: '1.0.0',
      pluginSdkVersion: '4.1.0',
      author: 'Test',
      description: 'Test plugin',
    );

/// Controllable user cubit for tests: states are pushed and writes recorded,
/// with no engine behind the facets.
class TestUserCubit extends Cubit<UserState> implements UserCubit {
  TestUserCubit(super.state);

  final StreamController<MediaItemType> _savedChanges =
      StreamController<MediaItemType>.broadcast();
  final StreamController<PlaylistTracksChanged> _edits =
      StreamController<PlaylistTracksChanged>.broadcast();
  final List<MediaItemType> refreshed = [];
  final List<bool> refreshNotifies = [];
  final List<String> toggledTracks = [];
  final List<String> toggledAlbums = [];
  final List<String> toggledArtists = [];
  final List<String> toggledPlaylists = [];
  final List<(String, String)> addedTracks = [];
  final List<(String, String)> removedTracks = [];
  AddTracksResult? nextAddResult;
  bool nextRemoveResult = true;
  int initializeCalls = 0;
  Future<void> Function()? onInitialize;

  void set(UserState state) => emit(state);

  @override
  bool get isAuthenticated => state.isAuthenticated;

  @override
  String? get userId => state.userId;

  @override
  Stream<bool> get authenticationChanges =>
      stream.map((s) => s.isAuthenticated).distinct();

  @override
  bool isTrackSaved(String id) => state.isTrackSaved(id);

  @override
  bool isAlbumSaved(String id) => state.isAlbumSaved(id);

  @override
  bool isArtistSaved(String id) => state.isArtistSaved(id);

  @override
  bool isPlaylistSaved(String id) => state.isPlaylistSaved(id);

  @override
  Future<void> toggleTrack(Track track) async {
    toggledTracks.add(track.id);
  }

  @override
  Future<void> toggleAlbum(Album album) async {
    toggledAlbums.add(album.id);
  }

  @override
  Future<void> toggleArtist(Artist artist) async {
    toggledArtists.add(artist.id);
  }

  @override
  Future<void> togglePlaylist(Playlist playlist) async {
    toggledPlaylists.add(playlist.id);
  }

  @override
  Stream<MediaItemType> get savedChanges => _savedChanges.stream;

  @override
  Future<void> refresh(MediaItemType type, {bool notify = true}) async {
    refreshed.add(type);
    refreshNotifies.add(notify);
  }

  void pushSavedChange(MediaItemType type) => _savedChanges.add(type);

  @override
  Stream<PlaylistTracksChanged> get playlistEdits => _edits.stream;

  @override
  Future<AddTracksResult?> addTrackToPlaylist(
    String playlistId,
    String trackId,
  ) async {
    addedTracks.add((playlistId, trackId));
    return nextAddResult;
  }

  @override
  Future<bool> removeTrackFromPlaylist(
    String playlistId,
    String trackId,
  ) async {
    removedTracks.add((playlistId, trackId));
    return nextRemoveResult;
  }

  void pushEdits(PlaylistTracksChanged event) => _edits.add(event);

  @override
  Future<void> initialize() async {
    initializeCalls++;
    await onInitialize?.call();
  }

  @override
  void reset() => emit(
    UserState(isAuthenticated: state.isAuthenticated, userId: state.userId),
  );

  @override
  Future<void> close() async {
    await _savedChanges.close();
    await _edits.close();
    return super.close();
  }
}

UserState testUserState({
  bool isAuthenticated = false,
  String? userId,
  Set<String> trackIds = const {},
  Set<String> albumIds = const {},
  Set<String> artistIds = const {},
  Set<String> playlistIds = const {},
  Set<MediaItemType> loaded = const {},
}) => UserState(
  isAuthenticated: isAuthenticated,
  userId: userId,
  trackIds: trackIds,
  albumIds: albumIds,
  artistIds: artistIds,
  playlistIds: playlistIds,
  loaded: loaded,
);
