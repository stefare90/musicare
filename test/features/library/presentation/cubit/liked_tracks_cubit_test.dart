import 'package:flutter_test/flutter_test.dart';
import 'package:musicare_metadata_host_sdk/musicare_metadata_host_sdk.dart';
import 'package:mocktail/mocktail.dart';
import 'package:music_are/features/plugin/metadata/data/repositories/library_repository.dart';
import 'package:music_are/core/notice/notice_bus.dart';
import 'package:music_are/features/library/presentation/cubit/liked_tracks_cubit.dart';
import 'package:music_are/features/plugin/metadata/data/services/metadata_plugin_engine.dart';
import 'package:music_are/features/plugin/metadata/presentation/cubit/user_cubit.dart';

import '../../../../helpers/metadata_plugin_test_helpers.dart';

class MockPluginEngine extends Mock implements MetadataPluginEngine {}

class MockMetadataPlugin extends Mock implements IMetadataPlugin {}

class MockUserService extends Mock implements IUser {}

/// Flips a saved set like [UserCubit] does; [failNext] leaves the set untouched
/// the way the real cubit restores it after a failed write.
class FakeFavorites implements UserFavorites {
  FakeFavorites(this.saved);

  final Set<String> saved;
  bool failNext = false;
  final List<Track> toggled = [];

  @override
  bool isTrackSaved(String id) => saved.contains(id);
  @override
  bool isAlbumSaved(String id) => saved.contains(id);
  @override
  bool isArtistSaved(String id) => saved.contains(id);
  @override
  bool isPlaylistSaved(String id) => saved.contains(id);

  @override
  Future<void> toggleTrack(Track track) async {
    toggled.add(track);
    if (failNext) return;
    if (!saved.remove(track.id)) saved.add(track.id);
  }

  @override
  Future<void> toggleAlbum(Album album) async {}
  @override
  Future<void> toggleArtist(Artist artist) async {}
  @override
  Future<void> togglePlaylist(Playlist playlist) async {}
}

void main() {
  late MockPluginEngine engine;
  late MockMetadataPlugin metadata;
  late MockUserService user;
  late NoticeBus notices;
  late LikedTracksCubit cubit;
  late TestUserCubit savedMedia;
  late FakeFavorites favorites;

  final track = Track(
    id: 't1',
    name: 'Song',
    externalUri: '',
    artists: [Artist(id: 'a1', name: 'Artist', externalUri: '')],
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

  setUp(() {
    engine = MockPluginEngine();
    metadata = MockMetadataPlugin();
    user = MockUserService();
    notices = NoticeBus();
    savedMedia = TestUserCubit(testUserState());
    favorites = FakeFavorites({'t1', 't2'});
    cubit = LikedTracksCubit(
      LibraryRepository(engine),
      notices,
      savedMedia: savedMedia,
      favorites: favorites,
    );

    when(() => engine.hasMetadata).thenReturn(true);
    when(() => engine.metadata).thenReturn(metadata);
    when(() => metadata.user).thenReturn(user);
  });

  tearDown(() async {
    await cubit.close();
    await savedMedia.close();
  });

  test('load fetches the first page of liked tracks', () async {
    when(
      () => user.savedTracks(offset: 0, limit: 20),
    ).thenAnswer(
      (_) async => PaginatedResult<Track>(
        items: [track],
        total: 1,
        offset: 0,
        limit: 20,
      ),
    );

    await cubit.load();

    expect(cubit.state.tracks.data.items.single.id, 't1');
    expect(cubit.state.tracks.error, isNull);
  });

  test('loadMore appends the next page', () async {
    when(
      () => user.savedTracks(offset: 0, limit: 20),
    ).thenAnswer(
      (_) async => PaginatedResult<Track>(
        items: [track],
        total: 2,
        offset: 0,
        limit: 20,
      ),
    );
    when(
      () => user.savedTracks(offset: 1, limit: 20),
    ).thenAnswer(
      (_) async => PaginatedResult<Track>(
        items: [track],
        total: 2,
        offset: 1,
        limit: 20,
      ),
    );

    await cubit.load();
    await cubit.loadMore();

    expect(cubit.state.tracks.data.items.length, 2);
  });

  test('a track change reloads the liked tracks', () async {
    when(
      () => user.savedTracks(offset: 0, limit: 20),
    ).thenAnswer(
      (_) async => PaginatedResult<Track>(
        items: [track],
        total: 1,
        offset: 0,
        limit: 20,
      ),
    );

    savedMedia.pushSavedChange(MediaItemType.track);
    await Future<void>.delayed(Duration.zero);

    expect(cubit.state.tracks.data.items.single.id, 't1');
  });

  test('removeTrack drops the track optimistically', () async {
    when(
      () => user.savedTracks(offset: 0, limit: 20),
    ).thenAnswer(
      (_) async => PaginatedResult<Track>(
        items: [track],
        total: 1,
        offset: 0,
        limit: 20,
      ),
    );

    await cubit.load();
    final removed = await cubit.removeTrack(track);

    expect(removed, isTrue);
    expect(cubit.state.tracks.data.items, isEmpty);
    expect(cubit.state.tracks.data.total, 0);
    expect(favorites.toggled, [track]);
    expect(favorites.isTrackSaved(track.id), isFalse);
  });

  test('a failed removal restores the track', () async {
    when(
      () => user.savedTracks(offset: 0, limit: 20),
    ).thenAnswer(
      (_) async => PaginatedResult<Track>(
        items: [track],
        total: 1,
        offset: 0,
        limit: 20,
      ),
    );

    await cubit.load();
    favorites.failNext = true;
    final removed = await cubit.removeTrack(track);

    expect(removed, isFalse);
    expect(cubit.state.tracks.data.items.single.id, 't1');
    expect(cubit.state.tracks.data.total, 1);
    expect(favorites.isTrackSaved(track.id), isTrue);
  });

  test("an own removal's saved change does not reload the list", () async {
    var fetches = 0;
    when(() => user.savedTracks(offset: 0, limit: 20)).thenAnswer(
      (_) async {
        fetches++;
        return PaginatedResult<Track>(
          items: [track],
          total: 1,
          offset: 0,
          limit: 20,
        );
      },
    );

    await cubit.load();
    expect(fetches, 1);

    savedMedia.pushSavedChange(MediaItemType.track);
    await Future<void>.delayed(Duration.zero);
    expect(fetches, 2);

    await cubit.removeTrack(track);
    savedMedia.pushSavedChange(MediaItemType.track);
    await Future<void>.delayed(Duration.zero);

    expect(fetches, 2);
  });

  group('pendingSource', () {
    test('returns null when nothing is loaded', () {
      expect(cubit.pendingSource(), isNull);
    });

    test('returns a source bound to the loaded window', () async {
      final second = Track(
        id: 't2',
        name: 'Song 2',
        externalUri: '',
        artists: [Artist(id: 'a1', name: 'Artist', externalUri: '')],
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
      when(
        () => user.savedTracks(offset: 0, limit: 20),
      ).thenAnswer(
        (_) async => PaginatedResult<Track>(
          items: [track],
          total: 2,
          offset: 0,
          limit: 20,
        ),
      );
      when(
        () => user.savedTracks(offset: 1, limit: 20),
      ).thenAnswer(
        (_) async => PaginatedResult<Track>(
          items: [second],
          total: 2,
          offset: 1,
          limit: 20,
        ),
      );

      await cubit.load();

      final source = cubit.pendingSource();
      expect(source, isNotNull);
      final pending = source!;
      expect(pending.nextOffset, equals(1));
      expect(pending.total, equals(2));

      final page = await pending.loader(pending.nextOffset);
      expect(page.items.single.id, equals('t2'));
    });

    test('returns null when the list is complete', () async {
      when(
        () => user.savedTracks(offset: 0, limit: 20),
      ).thenAnswer(
        (_) async => PaginatedResult<Track>(
          items: [track],
          total: 1,
          offset: 0,
          limit: 20,
        ),
      );

      await cubit.load();

      expect(cubit.pendingSource(), isNull);
    });
  });
}
