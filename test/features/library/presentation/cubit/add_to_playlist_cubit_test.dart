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
  late TestUserCubit savedMedia;
  late AddToPlaylistCubit cubit;

  final playlist = Playlist(
    id: 'pl1',
    name: 'Chill',
    description: '',
    externalUri: '',
    owner: User(id: 'me', name: 'me', externalUri: ''),
  );
  final otherPlaylist = Playlist(
    id: 'pl2',
    name: 'Someone else',
    description: '',
    externalUri: '',
    owner: User(id: 'other', name: 'other', externalUri: ''),
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
    savedMedia = TestUserCubit(testUserState());

    when(() => engine.hasMetadata).thenReturn(true);
    when(() => engine.metadata).thenReturn(metadata);
    when(() => metadata.user).thenReturn(user);
    when(() => metadata.playlist).thenReturn(playlists);
  });

  tearDown(() async {
    await cubit.close();
    await savedMedia.close();
  });

  AddToPlaylistCubit buildCubit({bool authenticated = true, String? userId = 'me'}) {
    return AddToPlaylistCubit(
      LibraryRepository(engine),
      PlaylistRepository(engine),
      notices,
      session: TestUserCubit(
        testUserState(isAuthenticated: authenticated, userId: userId),
      ),
      savedMedia: savedMedia,
      edits: savedMedia,
    );
  }

  PaginatedResult<Playlist> page(List<Playlist> items, {int? total}) =>
      PaginatedResult<Playlist>(
        items: items,
        total: total ?? items.length,
        offset: 0,
        limit: 100,
      );

  test('load lists only the playlists the user owns', () async {
    cubit = buildCubit();
    when(
      () => user.savedPlaylists(offset: 0, limit: 100),
    ).thenAnswer((_) async => page([playlist, otherPlaylist]));

    await cubit.load();

    expect(cubit.state.playlists.data.items.map((p) => p.id), ['pl1']);
    expect(cubit.state.playlists.data.total, 1);
  });

  test('load keeps fetching while the pages hold only other people playlists',
      () async {
    cubit = buildCubit();
    final other = List.generate(
      100,
      (i) => Playlist(
        id: 'other$i',
        name: 'Other $i',
        description: '',
        externalUri: '',
        owner: const User(id: 'other', name: 'other', externalUri: ''),
      ),
    );
    when(
      () => user.savedPlaylists(offset: 0, limit: 100),
    ).thenAnswer((_) async => page(other, total: 101));
    when(
      () => user.savedPlaylists(offset: 100, limit: 100),
    ).thenAnswer((_) async => page([playlist], total: 101));

    await cubit.load();

    expect(cubit.state.playlists.data.items.map((p) => p.id), ['pl1']);
  });

  test('load asks for sign-in when the session is anonymous', () async {
    cubit = buildCubit(authenticated: false, userId: null);

    await cubit.load();

    expect(cubit.state.playlists.error, isA<MetadataAuthRequiredException>());
    verifyNever(
      () => user.savedPlaylists(
        offset: any(named: 'offset'),
        limit: any(named: 'limit'),
      ),
    );
  });

  test('addTrack delegates the write to the facet', () async {
    cubit = buildCubit();
    savedMedia.nextAddResult = const AddTracksResult(
      added: 1,
      alreadyPresent: [],
    );

    final result = await cubit.addTrack(playlist, track);

    expect(result?.added, 1);
    expect(savedMedia.addedTracks, [('pl1', 't1')]);
  });

  test('addTrack returns the outcome when the track was already there',
      () async {
    cubit = buildCubit();
    savedMedia.nextAddResult = const AddTracksResult(
      added: 0,
      alreadyPresent: ['t1'],
    );

    final result = await cubit.addTrack(playlist, track);

    expect(result?.added, 0);
    expect(result?.alreadyPresent, ['t1']);
  });

  test('addTrack returns null when the facet reports a failure', () async {
    cubit = buildCubit();
    savedMedia.nextAddResult = null;

    final result = await cubit.addTrack(playlist, track);

    expect(result, isNull);
    expect(savedMedia.addedTracks, [('pl1', 't1')]);
  });

  test('createPlaylist resolves the user, adds the track and announces', () async {
    cubit = buildCubit();
    when(() => user.me()).thenAnswer((_) async => {'user_id': 'me'});
    when(
      () => playlists.createPlaylist(
        'me',
        'My list',
        description: 'desc',
        public_: true,
      ),
    ).thenAnswer((_) async => playlist);
    when(() => playlists.addTracks('pl1', ['t1'])).thenAnswer(
      (_) async => const AddTracksResult(added: 1, alreadyPresent: []),
    );

    final outcome = await cubit.createPlaylist(
      name: 'My list',
      description: 'desc',
      isPublic: true,
      trackIds: ['t1'],
    );

    expect(outcome?.playlist.id, 'pl1');
    expect(outcome?.trackAdded, isTrue);
    expect(savedMedia.refreshed, [MediaItemType.playlist]);
  });

  test('createPlaylist reports a partial success when the track fails',
      () async {
    cubit = buildCubit();
    when(() => user.me()).thenAnswer((_) async => {'user_id': 'me'});
    when(
      () => playlists.createPlaylist(
        'me',
        'My list',
        description: null,
        public_: false,
      ),
    ).thenAnswer((_) async => playlist);
    when(
      () => playlists.addTracks('pl1', ['t1']),
    ).thenAnswer((_) async => throw Exception('offline'));

    final outcome = await cubit.createPlaylist(name: 'My list', trackIds: ['t1']);

    expect(outcome?.playlist.id, 'pl1');
    expect(outcome?.trackAdded, isFalse);
    expect(savedMedia.refreshed, [MediaItemType.playlist]);
  });

  test('createPlaylist announces when sign-in is required', () async {
    cubit = buildCubit();
    when(() => user.me()).thenAnswer((_) async => const <String, dynamic>{});

    final seen = <Object>[];
    final subscription = notices.notices.listen(seen.add);
    final outcome = await cubit.createPlaylist(name: 'x');
    await Future<void>.delayed(Duration.zero);

    expect(outcome, isNull);
    expect((seen.single as ErrorNotice).error, isA<MetadataAuthRequiredException>());
    await subscription.cancel();
  });
}
