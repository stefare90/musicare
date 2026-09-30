import 'package:flutter_test/flutter_test.dart';
import 'package:musicare_metadata_host_sdk/musicare_metadata_host_sdk.dart';
import 'package:mocktail/mocktail.dart';
import 'package:music_are/core/models/section_state.dart';
import 'package:music_are/core/notice/notice_bus.dart';
import 'package:music_are/features/library/presentation/cubit/library_cubit.dart';
import 'package:music_are/features/library/presentation/cubit/library_state.dart';
import 'package:music_are/features/plugin/metadata/data/services/metadata_plugin_engine.dart';

class MockPluginEngine extends Mock implements MetadataPluginEngine {}

class MockMetadataPlugin extends Mock implements IMetadataPlugin {}

class MockUserService extends Mock implements IUser {}

class MockAuthService extends Mock implements IAuth {}

void main() {
  late MockPluginEngine engine;
  late MockMetadataPlugin metadata;
  late MockUserService user;
  late MockAuthService auth;
  late NoticeBus notices;
  late LibraryCubit cubit;

  final playlist = Playlist(
    id: 'pl1',
    name: 'Chill',
    description: '',
    externalUri: '',
    owner: User(id: 'u1', name: 'me', externalUri: ''),
  );
  final secondPlaylist = Playlist(
    id: 'pl2',
    name: 'Focus',
    description: '',
    externalUri: '',
    owner: User(id: 'u1', name: 'me', externalUri: ''),
  );

  setUp(() {
    engine = MockPluginEngine();
    metadata = MockMetadataPlugin();
    user = MockUserService();
    auth = MockAuthService();
    notices = NoticeBus();
    cubit = LibraryCubit(engine, notices);

    when(() => engine.hasMetadata).thenReturn(true);
    when(() => engine.metadata).thenReturn(metadata);
    when(() => metadata.auth).thenReturn(auth);
    when(() => metadata.user).thenReturn(user);
  });

  tearDown(() => cubit.close());

  PaginatedResult<T> page<T>(List<T> items, {int total = -1}) => PaginatedResult<T>(
    items: items,
    total: total < 0 ? items.length : total,
    offset: 0,
    limit: 20,
  );

  void stubEmptySections() {
    when(
      () => user.savedPlaylists(offset: any(named: 'offset'), limit: any(named: 'limit')),
    ).thenAnswer((_) async => page<Playlist>([]));
    when(
      () => user.savedAlbums(offset: any(named: 'offset'), limit: any(named: 'limit')),
    ).thenAnswer((_) async => page<Album>([]));
    when(
      () => user.savedArtists(offset: any(named: 'offset'), limit: any(named: 'limit')),
    ).thenAnswer((_) async => page<Artist>([]));
  }

  test('signed out: empties the sections without fetching', () async {
    when(() => auth.isAuthenticated()).thenAnswer((_) async => false);

    await cubit.loadAll();

    expect(cubit.state.isAuthenticated, isFalse);
    expect(cubit.state.playlists.data.items, isEmpty);
    verifyNever(
      () => user.savedPlaylists(offset: any(named: 'offset'), limit: any(named: 'limit')),
    );
  });

  test('signed in: loads the three account sections independently', () async {
    when(() => auth.isAuthenticated()).thenAnswer((_) async => true);
    stubEmptySections();
    when(
      () => user.savedPlaylists(offset: 0, limit: 20),
    ).thenAnswer((_) async => page<Playlist>([playlist]));

    await cubit.loadAll();
    // The three loads are fire-and-forget; let them settle.
    await Future<void>.delayed(Duration.zero);

    expect(cubit.state.isAuthenticated, isTrue);
    expect(cubit.state.playlists.data.items.single.id, 'pl1');
    expect(cubit.state.albums.data.items, isEmpty);
    expect(cubit.state.artists.data.items, isEmpty);
  });

  test('loadMore appends the next page of a section', () async {
    when(() => auth.isAuthenticated()).thenAnswer((_) async => true);
    stubEmptySections();
    when(
      () => user.savedPlaylists(offset: 0, limit: 20),
    ).thenAnswer((_) async => page<Playlist>([playlist], total: 2));
    when(
      () => user.savedPlaylists(offset: 1, limit: 20),
    ).thenAnswer((_) async => page<Playlist>([secondPlaylist], total: 2));

    await cubit.loadAll();
    await Future<void>.delayed(Duration.zero);
    await cubit.loadMore(LibrarySection.playlists);

    expect(cubit.state.playlists.data.items.length, 2);
    expect(cubit.state.playlists.data.items.last.id, 'pl2');
  });

  test('a failed load keeps the existing data and emits auth notices', () async {
    when(() => auth.isAuthenticated()).thenAnswer((_) async => true);
    stubEmptySections();
    when(
      () => user.savedPlaylists(offset: 0, limit: 20),
    ).thenAnswer((_) async => page<Playlist>([playlist], total: 2));
    when(
      () => user.savedPlaylists(offset: 1, limit: 20),
    ).thenAnswer((_) async {
      throw const MetadataAuthRequiredException('sign in');
    });

    await cubit.loadAll();
    await Future<void>.delayed(Duration.zero);

    final seen = <Object>[];
    final subscription = notices.notices.listen(seen.add);
    await cubit.loadMore(LibrarySection.playlists);
    await Future<void>.delayed(Duration.zero);

    expect(cubit.state.playlists.data.items.length, 1);
    expect(cubit.state.playlists.error, isA<MetadataAuthRequiredException>());
    expect(seen, hasLength(1));
    await subscription.cancel();
  });

  test('updateGridColumns rounds the page size to whole rows', () async {
    when(() => auth.isAuthenticated()).thenAnswer((_) async => true);
    stubEmptySections();

    cubit.updateGridColumns(3);
    await cubit.loadAll();
    await Future<void>.delayed(Duration.zero);

    verify(() => user.savedPlaylists(offset: 0, limit: 21)).called(1);
    verify(() => user.savedAlbums(offset: 0, limit: 21)).called(1);
  });

  test('a section starts in the loading state while fetching', () {
    expect(const LibraryState().playlists, isA<SectionState>());
  });
}
