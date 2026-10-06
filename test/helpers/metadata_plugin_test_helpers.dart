import 'dart:async';

import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:musicare_metadata_host_sdk/musicare_metadata_host_sdk.dart';
import 'package:mocktail/mocktail.dart';
import 'package:music_are/features/plugin/metadata/presentation/cubit/account_cubit.dart'
    as legacy;
import 'package:music_are/features/plugin/metadata/presentation/cubit/account_session.dart';
import 'package:music_are/features/plugin/metadata/presentation/cubit/account_state.dart';
import 'package:music_are/features/plugin/metadata/presentation/cubit/metadata_plugin_cubit.dart';
import 'package:music_are/features/plugin/metadata/presentation/cubit/metadata_plugin_state.dart';
import 'package:music_are/features/plugin/metadata/presentation/cubit/saved_media_index.dart';
import 'package:music_are/features/plugin/metadata/presentation/cubit/user_cubit.dart';
import 'package:music_are/features/plugin/shared/data/models/plugin_manifest.dart';

class MockMetadataPluginCubit extends Mock implements MetadataPluginCubit {}

class MockAccountCubit extends Mock implements legacy.AccountCubit {}

/// Controllable account cubit: tests can push [AccountState]s to simulate
/// sign-in/sign-out without an engine.
class TestAccountCubit extends Cubit<AccountState> implements AccountSession {
  TestAccountCubit(super.state);

  void set(AccountState state) => emit(state);

  @override
  bool get isAuthenticated => state.isAuthenticated;

  @override
  String? get userId => state.userId;

  @override
  Stream<bool> get authenticationChanges =>
      stream.map((s) => s.isAuthenticated).distinct();
}

/// A signed-out session for tests whose focus is not the account.
class TestAccountSession implements AccountSession {
  TestAccountSession({this.isAuthenticated = false, this.userId});

  @override
  final bool isAuthenticated;

  @override
  final String? userId;

  @override
  final Stream<bool> authenticationChanges = const Stream<bool>.empty();
}

/// Records the write notifications of the saved-media index and lets a test
/// push a change with [emit], without exercising the real index.
class TestSavedMediaIndex implements SavedMediaIndex {
  final StreamController<MediaItemType> _changes =
      StreamController<MediaItemType>.broadcast();
  final List<MediaItemType> refreshed = [];
  final List<bool> refreshNotifies = [];

  @override
  Stream<MediaItemType> get changes => _changes.stream;

  @override
  Future<void> refresh(MediaItemType type, {bool notify = true}) async {
    refreshed.add(type);
    refreshNotifies.add(notify);
  }

  void emit(MediaItemType type) => _changes.add(type);

  Future<void> close() => _changes.close();
}

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

MetadataPluginLoadedState testLoadedState({String pluginName = 'Test Provider'}) =>
    MetadataPluginLoadedState(manifest: testPluginManifest(name: pluginName));

AccountState testAccountState({bool isAuthenticated = false, String? userId}) =>
    AccountState(isAuthenticated: isAuthenticated, userId: userId);

/// Controllable user cubit: tests push [UserState]s and drive the facet
/// streams without an engine, and record the writes instead of performing
/// them.
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
  AuthResult nextSignInResult = AuthResult.authenticated;
  AddTracksResult? nextAddResult;
  bool nextRemoveResult = true;
  Future<AuthResult> Function()? onSignIn;
  Future<void> Function()? onSignOut;

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
  Stream<MediaItemType> get changes => _savedChanges.stream;

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
  Future<void> initialize() async {}

  @override
  Future<AuthResult> signIn() async {
    if (onSignIn != null) return onSignIn!();
    return nextSignInResult;
  }

  @override
  Future<void> signOut() async {
    await onSignOut?.call();
    emit(const UserState());
  }

  @override
  void reset() => emit(
    UserState(
      isAuthenticated: state.isAuthenticated,
      userId: state.userId,
    ),
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

MetadataPluginCubit buildMockMetadataPluginCubit({MetadataPluginState? state}) {
  final cubit = MockMetadataPluginCubit();
  when(() => cubit.state).thenReturn(state ?? testLoadedState());
  when(() => cubit.stream).thenAnswer((_) => const Stream.empty());
  return cubit;
}

legacy.AccountCubit buildMockAccountCubit({
  AccountState? state,
  Future<legacy.AuthResult> Function()? onSignIn,
  Future<void> Function()? onSignOut,
}) {
  final cubit = MockAccountCubit();
  when(() => cubit.state).thenReturn(state ?? testAccountState());
  when(() => cubit.stream).thenAnswer((_) => const Stream.empty());
  when(() => cubit.isAuthenticated).thenAnswer((_) => cubit.state.isAuthenticated);
  when(() => cubit.userId).thenAnswer((_) => cubit.state.userId);
  when(
    () => cubit.authenticationChanges,
  ).thenAnswer((_) => const Stream<bool>.empty());
  when(() => cubit.signIn()).thenAnswer(
    (_) async => onSignIn == null
        ? legacy.AuthResult.authenticated
        : await onSignIn(),
  );
  when(() => cubit.signOut()).thenAnswer((_) async {
    await onSignOut?.call();
  });
  return cubit;
}
