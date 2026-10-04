import 'package:flutter_test/flutter_test.dart';
import 'package:musicare_metadata_host_sdk/musicare_metadata_host_sdk.dart';
import 'package:mocktail/mocktail.dart';
import 'package:music_are/features/plugin/metadata/data/repositories/library_repository.dart';
import 'package:music_are/core/notice/notice_bus.dart';
import 'package:music_are/features/library/presentation/cubit/liked_tracks_cubit.dart';
import 'package:music_are/features/plugin/metadata/data/services/metadata_plugin_engine.dart';

import '../../../../helpers/metadata_plugin_test_helpers.dart';

class MockPluginEngine extends Mock implements MetadataPluginEngine {}

class MockMetadataPlugin extends Mock implements IMetadataPlugin {}

class MockUserService extends Mock implements IUser {}

void main() {
  late MockPluginEngine engine;
  late MockMetadataPlugin metadata;
  late MockUserService user;
  late NoticeBus notices;
  late LikedTracksCubit cubit;
  late TestSavedMediaIndex savedMedia;

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
    savedMedia = TestSavedMediaIndex();
    cubit = LikedTracksCubit(
      LibraryRepository(engine),
      notices,
      savedMedia: savedMedia,
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

    savedMedia.emit(MediaItemType.track);
    await Future<void>.delayed(Duration.zero);

    expect(cubit.state.tracks.data.items.single.id, 't1');
  });

  test('refresh reloads the list and refreshes the saved set silently',
      () async {
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

    await cubit.refresh();

    verify(() => user.savedTracks(offset: 0, limit: 20)).called(1);
    expect(savedMedia.refreshed, [MediaItemType.track]);
  });
}
