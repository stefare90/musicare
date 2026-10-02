import 'package:flutter_test/flutter_test.dart';
import 'package:musicare_metadata_host_sdk/musicare_metadata_host_sdk.dart';
import 'package:mocktail/mocktail.dart';
import 'package:music_are/features/plugin/metadata/data/repositories/playlist_repository.dart';
import 'package:music_are/features/plugin/metadata/data/repositories/library_repository.dart';
import 'package:music_are/core/notice/notice_bus.dart';
import 'package:music_are/features/library/presentation/cubit/add_to_playlist_cubit.dart';
import 'package:music_are/features/plugin/metadata/data/services/metadata_plugin_engine.dart';

import '../../../../helpers/metadata_plugin_test_helpers.dart';

class MockPluginEngine extends Mock implements MetadataPluginEngine {}

class MockMetadataPlugin extends Mock implements IMetadataPlugin {}

class MockUserService extends Mock implements IUser {}

class MockPlaylistService extends Mock implements IPlaylist {}

void main() {
  late MockPluginEngine engine;
  late MockMetadataPlugin metadata;
  late MockUserService user;
  late MockPlaylistService playlists;
  late NoticeBus notices;
  late AddToPlaylistCubit cubit;

  final playlist = Playlist(
    id: 'pl1',
    name: 'Chill',
    description: '',
    externalUri: '',
    owner: User(id: 'me', name: 'me', externalUri: ''),
  );
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

  setUp(() {
    engine = MockPluginEngine();
    metadata = MockMetadataPlugin();
    user = MockUserService();
    playlists = MockPlaylistService();
    notices = NoticeBus();

    when(() => engine.hasMetadata).thenReturn(true);
    when(() => engine.metadata).thenReturn(metadata);
    when(() => metadata.user).thenReturn(user);
    when(() => metadata.playlist).thenReturn(playlists);
  });

  tearDown(() => cubit.close());

  AddToPlaylistCubit buildCubit({bool authenticated = false}) {
    final authCubit = TestAccountCubit(
      testAccountState(isAuthenticated: authenticated),
    );
    return AddToPlaylistCubit(
      LibraryRepository(engine),
      PlaylistRepository(engine),
      notices,
      session: authCubit,
    );
  }

  test('load fetches the saved playlists', () async {
    cubit = buildCubit();
    when(
      () => user.savedPlaylists(offset: 0, limit: 20),
    ).thenAnswer(
      (_) async => PaginatedResult<Playlist>(
        items: [playlist],
        total: 1,
        offset: 0,
        limit: 20,
      ),
    );

    await cubit.load();

    expect(cubit.state.playlists.data.items.single.id, 'pl1');
  });

  test('addTrack reports failure on the bus', () async {
    cubit = buildCubit();
    when(
      () => playlists.addTracks('pl1', ['t1']),
    ).thenAnswer((_) async => throw const MetadataAuthRequiredException(''));

    final seen = <Object>[];
    final subscription = notices.notices.listen(seen.add);
    final ok = await cubit.addTrack(playlist, track);
    await Future<void>.delayed(Duration.zero);

    expect(ok, isFalse);
    expect(seen, hasLength(1));
    await subscription.cancel();
  });

  test('createPlaylist resolves the user and adds the track', () async {
    cubit = buildCubit(authenticated: true);
    when(() => user.me()).thenAnswer((_) async => {'user_id': 'me'});
    when(
      () => playlists.createPlaylist(
        'me',
        'My list',
        description: 'desc',
        public_: true,
      ),
    ).thenAnswer((_) async => playlist);
    when(() => playlists.addTracks('pl1', ['t1'])).thenAnswer((_) async {});

    final created = await cubit.createPlaylist(
      name: 'My list',
      description: 'desc',
      isPublic: true,
      trackIds: ['t1'],
    );

    expect(created?.id, 'pl1');
    verify(() => playlists.addTracks('pl1', ['t1'])).called(1);
  });

  test('createPlaylist announces when sign-in is required', () async {
    cubit = buildCubit();

    final seen = <Object>[];
    final subscription = notices.notices.listen(seen.add);
    final created = await cubit.createPlaylist(name: 'x');
    await Future<void>.delayed(Duration.zero);

    expect(created, isNull);
    expect(seen.single, isA<MetadataAuthRequiredException>());
    await subscription.cancel();
  });
}
