import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get_it/get_it.dart';
import 'package:musicare_metadata_host_sdk/musicare_metadata_host_sdk.dart';
import 'package:mocktail/mocktail.dart';
import 'package:music_are/features/plugin/metadata/data/repositories/library_repository.dart';
import 'package:music_are/core/l10n/app_localizations.dart';
import 'package:music_are/core/notice/notice_bus.dart';
import 'package:music_are/features/library/presentation/pages/liked_tracks_page.dart';
import 'package:music_are/features/player/presentation/cubit/player_cubit.dart';
import 'package:music_are/features/player/presentation/cubit/player_state.dart';
import 'package:music_are/features/plugin/metadata/data/services/metadata_plugin_engine.dart';
import 'package:music_are/features/plugin/metadata/presentation/cubit/user_cubit.dart';

import '../../../../helpers/metadata_plugin_test_helpers.dart';

class MockPluginEngine extends Mock implements MetadataPluginEngine {}

class MockMetadataPlugin extends Mock implements IMetadataPlugin {}

class MockUserService extends Mock implements IUser {}

class MockPlayerCubit extends Mock implements PlayerCubit {}

void main() {
  final sl = GetIt.instance;

  late MockPluginEngine engine;
  late MockMetadataPlugin metadata;
  late MockUserService user;
  late MockPlayerCubit playerCubit;
  late TestUserCubit userCubit;

  final track = Track(
    id: 't1',
    name: 'Come Together',
    externalUri: '',
    artists: [Artist(id: 'a1', name: 'The Beatles', externalUri: '')],
    album: const Album(
      id: 'al1',
      name: 'Abbey Road',
      artists: [],
      releaseDate: '1969',
      externalUri: '',
      totalTracks: 1,
      albumType: AlbumType.album,
    ),
    durationMs: 1000,
  );
  registerFallbackValue(track);

  setUp(() async {
    await sl.reset();
    engine = MockPluginEngine();
    metadata = MockMetadataPlugin();
    user = MockUserService();
    playerCubit = MockPlayerCubit();

    sl.registerLazySingleton<MetadataPluginEngine>(() => engine);
    sl.registerLazySingleton<NoticeBus>(() => NoticeBus());
  sl.registerLazySingleton<LibraryRepository>(() => LibraryRepository(engine));
    userCubit = TestUserCubit(testUserState());
    sl.registerLazySingleton<UserCubit>(() => userCubit);
    sl.registerLazySingleton<UserSavedMediaIndex>(
      () => sl<UserCubit>(),
    );

    when(() => playerCubit.state).thenReturn(const PlayerState());
    when(() => playerCubit.stream).thenAnswer((_) => const Stream.empty());

    when(() => engine.hasMetadata).thenReturn(true);
    when(() => engine.metadata).thenReturn(metadata);
    when(() => metadata.user).thenReturn(user);
  });

  Widget buildTestableWidget() {
    return MultiBlocProvider(
      providers: [
        BlocProvider<PlayerCubit>.value(value: playerCubit),
        BlocProvider<UserCubit>.value(value: userCubit),
      ],
      child: MaterialApp(
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: const LikedTracksPage(),
      ),
    );
  }

  testWidgets('renders the liked tracks', (tester) async {
    when(
      () => user.savedTracks(
        offset: any(named: 'offset'),
        limit: any(named: 'limit'),
      ),
    ).thenAnswer(
      (_) async => PaginatedResult<Track>(
        items: [track],
        total: 1,
        offset: 0,
        limit: 20,
      ),
    );

    await tester.pumpWidget(buildTestableWidget());
    await tester.pumpAndSettle();

    expect(find.text('Come Together'), findsOneWidget);
    expect(find.text('No liked songs yet'), findsNothing);
  });

  testWidgets('shows an empty state when there are no liked tracks', (
    tester,
  ) async {
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
        limit: 20,
      ),
    );

    await tester.pumpWidget(buildTestableWidget());
    await tester.pumpAndSettle();

    expect(find.text('No liked songs yet'), findsOneWidget);
  });

  testWidgets('track options offer Play Next and Add to Queue', (
    tester,
  ) async {
    when(
      () => user.savedTracks(
        offset: any(named: 'offset'),
        limit: any(named: 'limit'),
      ),
    ).thenAnswer(
      (_) async => PaginatedResult<Track>(
        items: [track],
        total: 1,
        offset: 0,
        limit: 20,
      ),
    );
    when(() => playerCubit.insertNext(any())).thenAnswer((_) {});
    when(() => playerCubit.addToQueue(any())).thenAnswer((_) {});

    await tester.pumpWidget(buildTestableWidget());
    await tester.pumpAndSettle();

    await tester.tap(find.byIcon(Icons.more_vert));
    await tester.pumpAndSettle();

    expect(find.text('Play Next'), findsOneWidget);
    expect(find.text('Add to Queue'), findsOneWidget);

    await tester.tap(find.text('Play Next'));
    await tester.pumpAndSettle();
    verify(() => playerCubit.insertNext(track)).called(1);

    await tester.tap(find.byIcon(Icons.more_vert));
    await tester.pumpAndSettle();

    await tester.tap(find.text('Add to Queue'));
    await tester.pumpAndSettle();
    verify(() => playerCubit.addToQueue(track)).called(1);
  });

  testWidgets('pull-to-refresh reloads the list and the saved set', (
    tester,
  ) async {
    when(
      () => user.savedTracks(
        offset: any(named: 'offset'),
        limit: any(named: 'limit'),
      ),
    ).thenAnswer(
      (_) async => PaginatedResult<Track>(
        items: [track],
        total: 1,
        offset: 0,
        limit: 20,
      ),
    );

    await tester.pumpWidget(buildTestableWidget());
    await tester.pumpAndSettle();
    clearInteractions(user);

    await tester.fling(find.text('Come Together'), const Offset(0, 300), 1000);
    await tester.pumpAndSettle();

    verify(() => user.savedTracks(offset: 0, limit: 20)).called(1);
  });
}
