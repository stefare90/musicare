import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:musicare_metadata_host_sdk/musicare_metadata_host_sdk.dart';
import 'package:mocktail/mocktail.dart';
import 'package:music_are/core/notice/notice_bus.dart';
import 'package:music_are/core/services/preferences_service.dart';
import 'package:music_are/features/plugin/metadata/data/repositories/account_repository.dart';
import 'package:music_are/features/plugin/metadata/data/repositories/library_repository.dart';
import 'package:music_are/features/plugin/metadata/data/repositories/playlist_repository.dart';
import 'package:music_are/features/plugin/metadata/data/services/metadata_plugin_engine.dart';
import 'package:music_are/features/plugin/metadata/presentation/cubit/user_cubit.dart';

class MockPluginEngine extends Mock implements MetadataPluginEngine {}

class MockMetadataPlugin extends Mock implements IMetadataPlugin {}

class MockAuthService extends Mock implements IAuth {}

class MockUserService extends Mock implements IUser {}

class MockTrackService extends Mock implements ITrack {}

class MockAlbumService extends Mock implements IAlbum {}

class MockPlaylistService extends Mock implements IPlaylist {}

class MockPreferencesService extends Mock implements PreferencesService {}

void main() {
  late MockPluginEngine engine;
  late MockMetadataPlugin metadata;
  late MockAuthService auth;
  late MockUserService user;
  late MockTrackService tracks;
  late MockAlbumService albums;
  late MockPlaylistService playlists;
  late MockPreferencesService preferences;
  late NoticeBus notices;
  late UserCubit cubit;
  late List<MediaItemType> savedChanges;
  late StreamSubscription<MediaItemType> savedChangesSubscription;
  String? cachedUserId;

  final track = Track(
    id: 't1',
    name: 'Song',
    externalUri: '',
    artists: const [],
    album: const Album(
      id: 'al1',
      name: 'Album',
      artists: [],
      releaseDate: '',
      externalUri: '',
      totalTracks: 1,
      albumType: AlbumType.album,
    ),
    durationMs: 1000,
  );

  const album = Album(
    id: 'al1',
    name: 'Album',
    artists: [],
    releaseDate: '',
    externalUri: '',
    totalTracks: 1,
    albumType: AlbumType.album,
  );

  const originalPlaylist = Playlist(
    id: 'pl-original',
    name: 'Weekly Exploration',
    description: '',
    externalUri: '',
    owner: User(id: 'other', name: 'other', externalUri: ''),
  );

  setUp(() {
    engine = MockPluginEngine();
    metadata = MockMetadataPlugin();
    auth = MockAuthService();
    user = MockUserService();
    tracks = MockTrackService();
    albums = MockAlbumService();
    playlists = MockPlaylistService();
    preferences = MockPreferencesService();
    notices = NoticeBus();
    cachedUserId = null;

    when(() => preferences.getMetadataUserId()).thenAnswer((_) => cachedUserId);
    when(() => preferences.setMetadataUserId(any())).thenAnswer((
      invocation,
    ) async {
      cachedUserId = invocation.positionalArguments.first as String;
      return true;
    });
    when(() => preferences.removeMetadataUserId()).thenAnswer((_) async {
      cachedUserId = null;
      return true;
    });

    cubit = UserCubit(
      AccountRepository(engine, preferences),
      LibraryRepository(engine),
      notices,
      PlaylistRepository(engine),
    );
    savedChanges = [];
    savedChangesSubscription = cubit.savedChanges.listen(savedChanges.add);

    when(() => engine.hasMetadata).thenReturn(true);
    when(() => engine.metadata).thenReturn(metadata);
    when(() => metadata.auth).thenReturn(auth);
    when(() => metadata.user).thenReturn(user);
    when(() => metadata.track).thenReturn(tracks);
    when(() => metadata.album).thenReturn(albums);
    when(() => metadata.playlist).thenReturn(playlists);
  });

  tearDown(() async {
    await savedChangesSubscription.cancel();
    await cubit.close();
  });

  void stubEmptyLibrary() {
    when(
      () => user.savedAlbums(
        offset: any(named: 'offset'),
        limit: any(named: 'limit'),
      ),
    ).thenAnswer(
      (_) async => const PaginatedResult<Album>(
        items: [],
        total: 0,
        offset: 0,
        limit: 100,
      ),
    );
    when(
      () => user.savedArtists(
        offset: any(named: 'offset'),
        limit: any(named: 'limit'),
      ),
    ).thenAnswer(
      (_) async => const PaginatedResult<Artist>(
        items: [],
        total: 0,
        offset: 0,
        limit: 100,
      ),
    );
    when(
      () => user.savedPlaylists(
        offset: any(named: 'offset'),
        limit: any(named: 'limit'),
      ),
    ).thenAnswer(
      (_) async => const PaginatedResult<Playlist>(
        items: [],
        total: 0,
        offset: 0,
        limit: 100,
      ),
    );
    when(
      () => user.savedTracks(
        offset: any(named: 'offset'),
        limit: any(named: 'limit'),
      ),
    ).thenAnswer(
      (_) async => const PaginatedResult<Track>(
        items: [],
        total: 0,
        offset: 0,
        limit: 100,
      ),
    );
  }

  /// Signs in against an empty library, so the warm-up settles the index.
  Future<void> signIn({String userId = 'u1'}) async {
    stubEmptyLibrary();
    when(() => auth.authenticate()).thenAnswer((_) async {});
    when(() => auth.isAuthenticated()).thenAnswer((_) async => true);
    when(() => user.me()).thenAnswer((_) async => {'user_id': userId});
    await cubit.signIn();
    await Future<void>.delayed(const Duration(milliseconds: 1));
  }

  group('saved index', () {
    void stubLoadFailure(MediaItemType type) {
      switch (type) {
        case MediaItemType.track:
          when(
            () => user.savedTracks(
              offset: any(named: 'offset'),
              limit: any(named: 'limit'),
            ),
          ).thenAnswer((_) async => throw Exception('timeout'));
        case MediaItemType.album:
          when(
            () => user.savedAlbums(
              offset: any(named: 'offset'),
              limit: any(named: 'limit'),
            ),
          ).thenAnswer((_) async => throw Exception('timeout'));
        case MediaItemType.artist:
          when(
            () => user.savedArtists(
              offset: any(named: 'offset'),
              limit: any(named: 'limit'),
            ),
          ).thenAnswer((_) async => throw Exception('timeout'));
        case MediaItemType.playlist:
          when(
            () => user.savedPlaylists(
              offset: any(named: 'offset'),
              limit: any(named: 'limit'),
            ),
          ).thenAnswer((_) async => throw Exception('timeout'));
      }
    }

    for (final type in MediaItemType.values) {
      test('a failed $type load stays silent and leaves it unmarked', () async {
        stubEmptyLibrary();
        stubLoadFailure(type);
        when(() => auth.authenticate()).thenAnswer((_) async {});
        when(() => auth.isAuthenticated()).thenAnswer((_) async => true);
        when(() => user.me()).thenAnswer((_) async => {'user_id': 'u1'});

        final seen = <Object>[];
        final subscription = notices.notices.listen(seen.add);

        await cubit.signIn();
        await pumpEventQueue();

        expect(seen, isEmpty);
        expect(cubit.state.loaded.contains(type), isFalse);
        await subscription.cancel();
      });
    }

    test('a loaded index marks every type without notifying', () async {
      final seen = <Object>[];
      final subscription = notices.notices.listen(seen.add);

      await signIn();
      await pumpEventQueue();

      expect(seen, isEmpty);
      expect(cubit.state.loaded, MediaItemType.values.toSet());
      await subscription.cancel();
    });

    test('toggling an empty id saves nothing and stays silent', () async {
      const ghost = Artist(id: '', name: 'No MBID', externalUri: '');
      final seen = <Object>[];
      final subscription = notices.notices.listen(seen.add);

      await cubit.toggleArtist(ghost);
      await pumpEventQueue();

      expect(cubit.isArtistSaved(''), isFalse);
      expect(cubit.state.artistIds, isEmpty);
      expect(seen, isEmpty);
      await subscription.cancel();
    });
  });

  group('account', () {
    test('initialize emits the authenticated identity', () async {
      stubEmptyLibrary();
      when(() => auth.isAuthenticated()).thenAnswer((_) async => true);
      when(() => user.me()).thenAnswer((_) async => {'user_id': 'listener'});

      await cubit.initialize();
      await pumpEventQueue();

      expect(cubit.state.isAuthenticated, isTrue);
      expect(cubit.state.userId, 'listener');
      expect(cachedUserId, 'listener');
    });

    test('initialize stays signed out when not authenticated', () async {
      when(() => auth.isAuthenticated()).thenAnswer((_) async => false);

      await cubit.initialize();

      expect(cubit.state.isAuthenticated, isFalse);
      expect(cubit.state.userId, isNull);
    });

    test('initialize keeps the account usable when the identity times out',
        () async {
      stubEmptyLibrary();
      when(() => auth.isAuthenticated()).thenAnswer((_) async => true);
      when(() => user.me()).thenAnswer((_) async => throw Exception('timeout'));

      await cubit.initialize();
      await pumpEventQueue();

      expect(cubit.state.isAuthenticated, isTrue);
      expect(cubit.state.userId, isNull);
    });

    test('initialize restores the cached identity when the provider is offline',
        () async {
      stubEmptyLibrary();
      cachedUserId = 'cached-listener';
      when(() => auth.isAuthenticated()).thenAnswer((_) async => true);
      when(() => user.me()).thenAnswer((_) async => throw Exception('offline'));

      await cubit.initialize();
      await pumpEventQueue();

      expect(cubit.state.isAuthenticated, isTrue);
      expect(cubit.state.userId, 'cached-listener');
    });

    test('initialize refreshes a stale cached identity', () async {
      stubEmptyLibrary();
      cachedUserId = 'old-name';
      when(() => auth.isAuthenticated()).thenAnswer((_) async => true);
      when(() => user.me()).thenAnswer((_) async => {'user_id': 'new-name'});

      await cubit.initialize();
      expect(cubit.state.userId, 'old-name');

      await pumpEventQueue();

      expect(cubit.state.userId, 'new-name');
      expect(cachedUserId, 'new-name');
    });

    test('signIn authenticates and reports success with the user name',
        () async {
      stubEmptyLibrary();
      when(() => auth.authenticate()).thenAnswer((_) async {});
      when(() => auth.isAuthenticated()).thenAnswer((_) async => true);
      when(() => user.me()).thenAnswer((_) async => {'user_id': 'listener'});

      final result = await cubit.signIn();

      expect(result, AuthResult.authenticated);
      expect(cubit.state.isAuthenticated, isTrue);
      expect(cubit.state.userId, 'listener');
      expect(cachedUserId, 'listener');
    });

    test('signIn reports cancellation when the form is dismissed', () async {
      when(() => auth.authenticate()).thenAnswer((_) async {});
      when(() => auth.isAuthenticated()).thenAnswer((_) async => false);

      final result = await cubit.signIn();

      expect(result, AuthResult.cancelled);
      expect(cubit.state.isAuthenticated, isFalse);
    });

    test('signIn reports failure and keeps the signed-out state', () async {
      when(
        () => auth.authenticate(),
      ).thenThrow(const MetadataAuthRequiredException('bad token'));

      final result = await cubit.signIn();

      expect(result, AuthResult.failed);
      expect(cubit.state.isAuthenticated, isFalse);
    });

    test('signIn succeeds even when the identity cannot be resolved', () async {
      stubEmptyLibrary();
      when(() => auth.authenticate()).thenAnswer((_) async {});
      when(() => auth.isAuthenticated()).thenAnswer((_) async => true);
      when(() => user.me()).thenAnswer((_) async => throw Exception('timeout'));

      final result = await cubit.signIn();

      expect(result, AuthResult.authenticated);
      expect(cubit.state.isAuthenticated, isTrue);
      expect(cubit.state.userId, isNull);
    });

    test('signIn falls back to the cached identity when resolution fails',
        () async {
      stubEmptyLibrary();
      cachedUserId = 'cached-listener';
      when(() => auth.authenticate()).thenAnswer((_) async {});
      when(() => auth.isAuthenticated()).thenAnswer((_) async => true);
      when(() => user.me()).thenAnswer((_) async => throw Exception('timeout'));

      final result = await cubit.signIn();

      expect(result, AuthResult.authenticated);
      expect(cubit.state.userId, 'cached-listener');
    });

    test('signOut clears the identity and the index', () async {
      await signIn();
      cubit.emit(cubit.state.withIds(MediaItemType.track, {'t1'}));

      when(() => auth.logout()).thenAnswer((_) async {});
      await cubit.signOut();

      expect(cubit.state.isAuthenticated, isFalse);
      expect(cubit.state.userId, isNull);
      expect(cubit.state.trackIds, isEmpty);
      expect(cachedUserId, isNull);
    });

    test('authenticationChanges drops a repeated sign-in value', () async {
      stubEmptyLibrary();
      final seen = <bool>[];
      final subscription = cubit.authenticationChanges.listen(seen.add);

      when(() => auth.isAuthenticated()).thenAnswer((_) async => true);
      when(() => user.me()).thenAnswer((_) async => {'user_id': 'listener'});
      await cubit.initialize();
      await pumpEventQueue();
      cubit.emit(const UserState(isAuthenticated: true, userId: 'renamed'));
      await Future<void>.delayed(Duration.zero);

      expect(seen, [true]);

      when(() => auth.logout()).thenAnswer((_) async {});
      await cubit.signOut();
      await Future<void>.delayed(Duration.zero);

      expect(seen, [true, false]);
      await subscription.cancel();
    });

    test('isAuthenticated mirrors the current state', () async {
      stubEmptyLibrary();
      expect(cubit.isAuthenticated, isFalse);

      when(() => auth.isAuthenticated()).thenAnswer((_) async => true);
      when(() => user.me()).thenAnswer((_) async => {'user_id': 'listener'});
      await cubit.initialize();

      expect(cubit.isAuthenticated, isTrue);
    });
  });

  group('saved index', () {
    test('warms the saved index when the account signs in', () async {
      stubEmptyLibrary();
      when(() => user.savedTracks(offset: 0, limit: 100)).thenAnswer(
        (_) async => PaginatedResult<Track>(
          items: [track],
          total: 1,
          offset: 0,
          limit: 100,
        ),
      );
      when(() => auth.authenticate()).thenAnswer((_) async {});
      when(() => auth.isAuthenticated()).thenAnswer((_) async => true);
      when(() => user.me()).thenAnswer((_) async => {'user_id': 'u1'});

      await cubit.signIn();
      await Future<void>.delayed(const Duration(milliseconds: 1));

      expect(cubit.isTrackSaved('t1'), isTrue);
    });

    test('fetches nothing while signed out', () async {
      await Future<void>.delayed(const Duration(milliseconds: 1));

      verifyNever(
        () => user.savedTracks(
          offset: any(named: 'offset'),
          limit: any(named: 'limit'),
        ),
      );
      verifyNever(
        () => user.savedAlbums(
          offset: any(named: 'offset'),
          limit: any(named: 'limit'),
        ),
      );
    });

    test('toggleTrack flips optimistically and rolls back on failure',
        () async {
      final completer = Completer<void>();
      when(() => tracks.save(['t1'])).thenAnswer((_) => completer.future);

      final seen = <Object>[];
      final subscription = notices.notices.listen(seen.add);

      final future = cubit.toggleTrack(track);
      expect(cubit.isTrackSaved('t1'), isTrue);

      completer.completeError(const MetadataAuthRequiredException('sign in'));
      await future;
      await Future<void>.delayed(Duration.zero);

      expect(cubit.isTrackSaved('t1'), isFalse);
      expect(seen, hasLength(1));
      await subscription.cancel();
    });

    test('toggleTrack on a saved track calls unsave', () async {
      when(() => tracks.unsave(['t1'])).thenAnswer((_) async {});
      cubit.emit(cubit.state.withIds(MediaItemType.track, {'t1'}));

      await cubit.toggleTrack(track);

      expect(cubit.isTrackSaved('t1'), isFalse);
      verify(() => tracks.unsave(['t1'])).called(1);
      verifyNever(() => tracks.save(any()));
    });

    test('a playlist save re-reads the library instead of trusting the id',
        () async {
      when(() => playlists.save('pl-original')).thenAnswer((_) async {});

      await signIn();

      const copy = Playlist(
        id: 'pl-copy',
        name: 'Weekly Exploration',
        description: '',
        externalUri: '',
        owner: User(id: 'me', name: 'me', externalUri: ''),
      );
      when(
        () => user.savedPlaylists(
          offset: any(named: 'offset'),
          limit: any(named: 'limit'),
        ),
      ).thenAnswer(
        (_) async => const PaginatedResult<Playlist>(
          items: [copy],
          total: 1,
          offset: 0,
          limit: 100,
        ),
      );

      await cubit.togglePlaylist(originalPlaylist);
      await Future<void>.delayed(Duration.zero);

      expect(cubit.state.playlistIds, {'pl-copy'});
    });

    test('reset clears the cached IDs but keeps the sign-in', () async {
      cubit.emit(
        const UserState(
          isAuthenticated: true,
          userId: 'u1',
          trackIds: {'t1'},
          loaded: {MediaItemType.track},
        ),
      );

      cubit.reset();

      expect(cubit.state.trackIds, isEmpty);
      expect(cubit.state.loaded, isEmpty);
      expect(cubit.state.isAuthenticated, isTrue);
      expect(cubit.state.userId, 'u1');
    });

    test('drops the index when the account signs out', () async {
      await signIn();
      cubit.emit(cubit.state.withIds(MediaItemType.track, {'t1'}));

      when(() => auth.logout()).thenAnswer((_) async {});
      await cubit.signOut();
      await Future<void>.delayed(Duration.zero);

      expect(cubit.state.trackIds, isEmpty);
    });

    test('the warm-up announces nothing', () async {
      stubEmptyLibrary();
      when(() => user.savedTracks(offset: 0, limit: 100)).thenAnswer(
        (_) async => PaginatedResult<Track>(
          items: [track],
          total: 1,
          offset: 0,
          limit: 100,
        ),
      );
      when(() => auth.authenticate()).thenAnswer((_) async {});
      when(() => auth.isAuthenticated()).thenAnswer((_) async => true);
      when(() => user.me()).thenAnswer((_) async => {'user_id': 'u1'});

      await cubit.signIn();
      await Future<void>.delayed(const Duration(milliseconds: 1));

      expect(cubit.state.trackIds, {'t1'});
      expect(savedChanges, isEmpty);
    });

    test('a successful toggle announces the type', () async {
      when(() => tracks.save(['t1'])).thenAnswer((_) async {});

      await cubit.toggleTrack(track);
      await Future<void>.delayed(Duration.zero);

      expect(cubit.isTrackSaved('t1'), isTrue);
      expect(savedChanges, [MediaItemType.track]);
    });

    test('a failed toggle announces nothing', () async {
      when(
        () => tracks.save(['t1']),
      ).thenAnswer((_) async => throw const MetadataAuthRequiredException(''));

      await cubit.toggleTrack(track);

      expect(cubit.isTrackSaved('t1'), isFalse);
      expect(savedChanges, isEmpty);
    });

    test('refresh announces only when the saved set differs', () async {
      await signIn();
      expect(savedChanges, isEmpty);

      await cubit.refresh(MediaItemType.album);
      await Future<void>.delayed(Duration.zero);
      expect(savedChanges, isEmpty);

      when(() => user.savedAlbums(offset: 0, limit: 100)).thenAnswer(
        (_) async => const PaginatedResult<Album>(
          items: [album],
          total: 1,
          offset: 0,
          limit: 100,
        ),
      );
      await cubit.refresh(MediaItemType.album);
      await Future<void>.delayed(Duration.zero);

      expect(cubit.state.albumIds, {'al1'});
      expect(savedChanges, [MediaItemType.album]);
    });

    test('reset announces nothing and clears the index', () async {
      when(() => tracks.save(['t1'])).thenAnswer((_) async {});
      await cubit.toggleTrack(track);
      await Future<void>.delayed(Duration.zero);
      expect(savedChanges, [MediaItemType.track]);

      cubit.reset();

      expect(cubit.state.trackIds, isEmpty);
      expect(savedChanges, [MediaItemType.track]);
    });

    test('an in-flight load cannot populate the next account index', () async {
      final hanging = Completer<PaginatedResult<Album>>();
      stubEmptyLibrary();
      when(
        () => user.savedAlbums(
          offset: any(named: 'offset'),
          limit: any(named: 'limit'),
        ),
      ).thenAnswer((_) => hanging.future);

      await signIn();
      await Future<void>.delayed(const Duration(milliseconds: 1));

      cubit.reset();
      await Future<void>.delayed(Duration.zero);

      const bAlbum = Album(
        id: 'b1',
        name: 'B Album',
        artists: [],
        releaseDate: '',
        externalUri: '',
        totalTracks: 1,
        albumType: AlbumType.album,
      );
      when(
        () => user.savedAlbums(
          offset: any(named: 'offset'),
          limit: any(named: 'limit'),
        ),
      ).thenAnswer(
        (_) async => const PaginatedResult<Album>(
          items: [bAlbum],
          total: 1,
          offset: 0,
          limit: 100,
        ),
      );
      await cubit.refresh(MediaItemType.album);

      hanging.complete(
        const PaginatedResult<Album>(
          items: [album],
          total: 1,
          offset: 0,
          limit: 100,
        ),
      );
      await Future<void>.delayed(const Duration(milliseconds: 1));

      expect(cubit.state.albumIds, {'b1'});
    });
  });

  group('playlist edits', () {
    test('addTrackToPlaylist returns the provider outcome', () async {
      const result = AddTracksResult(added: 1, alreadyPresent: []);
      when(() => playlists.addTracks('pl1', ['t1'])).thenAnswer(
        (_) async => result,
      );

      final outcome = await cubit.addTrackToPlaylist('pl1', 't1');

      expect(outcome, result);
      verify(() => playlists.addTracks('pl1', ['t1'])).called(1);
    });

    test('addTrackToPlaylist returns null and notifies on failure', () async {
      when(
        () => playlists.addTracks('pl1', ['t1']),
      ).thenAnswer((_) async => throw const MetadataAuthRequiredException(''));

      final seen = <Object>[];
      final subscription = notices.notices.listen(seen.add);

      final outcome = await cubit.addTrackToPlaylist('pl1', 't1');
      await Future<void>.delayed(Duration.zero);

      expect(outcome, isNull);
      expect(seen, hasLength(1));
      await subscription.cancel();
    });

    test('removeTrackFromPlaylist returns true on success', () async {
      when(() => playlists.removeTracks('pl1', ['t1'])).thenAnswer(
        (_) async {},
      );

      final removed = await cubit.removeTrackFromPlaylist('pl1', 't1');

      expect(removed, isTrue);
      verify(() => playlists.removeTracks('pl1', ['t1'])).called(1);
    });

    test('removeTrackFromPlaylist returns false and notifies on failure',
        () async {
      when(
        () => playlists.removeTracks('pl1', ['t1']),
      ).thenAnswer((_) async => throw const MetadataAuthRequiredException(''));

      final seen = <Object>[];
      final subscription = notices.notices.listen(seen.add);

      final removed = await cubit.removeTrackFromPlaylist('pl1', 't1');
      await Future<void>.delayed(Duration.zero);

      expect(removed, isFalse);
      expect(seen, hasLength(1));
      await subscription.cancel();
    });

    test('addTrackToPlaylist announces the addition', () async {
      when(() => playlists.addTracks('pl1', ['t1'])).thenAnswer(
        (_) async => const AddTracksResult(added: 1, alreadyPresent: []),
      );

      final seen = <PlaylistTracksChanged>[];
      final subscription = cubit.playlistEdits.listen(seen.add);
      await cubit.addTrackToPlaylist('pl1', 't1');
      await Future<void>.delayed(Duration.zero);

      expect(seen, hasLength(1));
      expect(seen.single.playlistId, 'pl1');
      expect(seen.single.added, ['t1']);
      expect(seen.single.removed, isEmpty);
      await subscription.cancel();
    });

    test('addTrackToPlaylist announces nothing when already present', () async {
      when(() => playlists.addTracks('pl1', ['t1'])).thenAnswer(
        (_) async => const AddTracksResult(added: 0, alreadyPresent: ['t1']),
      );

      final seen = <PlaylistTracksChanged>[];
      final subscription = cubit.playlistEdits.listen(seen.add);
      final result = await cubit.addTrackToPlaylist('pl1', 't1');
      await Future<void>.delayed(Duration.zero);

      expect(result?.added, 0);
      expect(seen, isEmpty);
      await subscription.cancel();
    });

    test('addTrackToPlaylist announces nothing on failure', () async {
      when(
        () => playlists.addTracks('pl1', ['t1']),
      ).thenAnswer((_) async => throw const MetadataAuthRequiredException(''));

      final seen = <PlaylistTracksChanged>[];
      final subscription = cubit.playlistEdits.listen(seen.add);
      final result = await cubit.addTrackToPlaylist('pl1', 't1');
      await Future<void>.delayed(Duration.zero);

      expect(result, isNull);
      expect(seen, isEmpty);
      await subscription.cancel();
    });

    test('removeTrackFromPlaylist announces the removal', () async {
      when(() => playlists.removeTracks('pl1', ['t1'])).thenAnswer(
        (_) async {},
      );

      final seen = <PlaylistTracksChanged>[];
      final subscription = cubit.playlistEdits.listen(seen.add);
      final removed = await cubit.removeTrackFromPlaylist('pl1', 't1');
      await Future<void>.delayed(Duration.zero);

      expect(removed, isTrue);
      expect(seen, hasLength(1));
      expect(seen.single.playlistId, 'pl1');
      expect(seen.single.added, isEmpty);
      expect(seen.single.removed, ['t1']);
      await subscription.cancel();
    });
  });
}
