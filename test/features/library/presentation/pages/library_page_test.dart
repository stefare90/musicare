import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get_it/get_it.dart';
import 'package:musicare_metadata_host_sdk/musicare_metadata_host_sdk.dart';
import 'package:mocktail/mocktail.dart';
import 'package:music_are/features/plugin/metadata/data/repositories/library_repository.dart';
import 'package:music_are/features/plugin/metadata/data/repositories/playlist_repository.dart';
import 'package:music_are/core/l10n/app_localizations.dart';
import 'package:music_are/core/notice/notice_bus.dart';
import 'package:music_are/features/library/presentation/pages/library_page.dart';
import 'package:music_are/features/plugin/metadata/data/services/metadata_plugin_engine.dart';
import 'package:music_are/features/plugin/metadata/presentation/cubit/account_cubit.dart';
import 'package:music_are/features/plugin/metadata/presentation/cubit/metadata_plugin_cubit.dart';
import 'package:music_are/features/plugin/metadata/presentation/cubit/metadata_plugin_state.dart';
import 'package:music_are/features/plugin/metadata/presentation/cubit/saved_media_cubit.dart';

import '../../../../helpers/metadata_plugin_test_helpers.dart';

class MockPluginEngine extends Mock implements MetadataPluginEngine {}

class MockMetadataPlugin extends Mock implements IMetadataPlugin {}

class MockUserService extends Mock implements IUser {}

void main() {
  final sl = GetIt.instance;

  late MockPluginEngine engine;
  late MockMetadataPlugin metadata;
  late MockUserService user;
  late AccountCubit authCubit;

  final playlist = Playlist(
    id: 'pl1',
    name: 'Chill Vibes',
    description: '',
    externalUri: '',
    owner: User(id: 'u1', name: 'me', externalUri: ''),
  );

  setUp(() async {
    await sl.reset();
    engine = MockPluginEngine();
    metadata = MockMetadataPlugin();
    user = MockUserService();

    sl.registerLazySingleton<MetadataPluginEngine>(() => engine);
    sl.registerLazySingleton<NoticeBus>(() => NoticeBus());
  sl.registerLazySingleton<LibraryRepository>(() => LibraryRepository(engine));
    sl.registerLazySingleton<PlaylistRepository>(
      () => PlaylistRepository(engine),
    );
    authCubit = buildMockAccountCubit(state: testAccountState());
    sl.registerLazySingleton<AccountCubit>(() => authCubit);
    sl.registerLazySingleton<SavedMediaCubit>(
      () => SavedMediaCubit(
        sl<LibraryRepository>(),
        sl<NoticeBus>(),
        session: sl<AccountCubit>(),
      ),
    );

    when(() => engine.hasMetadata).thenReturn(true);
    when(() => engine.metadata).thenReturn(metadata);
    when(() => metadata.user).thenReturn(user);

    when(
      () => user.savedAlbums(
        offset: any(named: 'offset'),
        limit: any(named: 'limit'),
      ),
    ).thenAnswer(
      (_) async =>
          const PaginatedResult<Album>(items: [], total: 0, offset: 0, limit: 20),
    );
    when(
      () => user.savedArtists(
        offset: any(named: 'offset'),
        limit: any(named: 'limit'),
      ),
    ).thenAnswer(
      (_) async =>
          const PaginatedResult<Artist>(items: [], total: 0, offset: 0, limit: 20),
    );
  });

  Widget buildTestableWidget(MetadataPluginCubit cubit) {
    return MultiBlocProvider(
      providers: [
        BlocProvider<MetadataPluginCubit>.value(value: cubit),
        BlocProvider<AccountCubit>.value(value: sl<AccountCubit>()),
      ],
      child: MaterialApp(
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: const LibraryPage(),
      ),
    );
  }

  testWidgets('signed out shows the sign-in invitation', (tester) async {
    await tester.pumpWidget(
      buildTestableWidget(buildMockMetadataPluginCubit()),
    );
    await tester.pumpAndSettle();

    expect(find.text('Sign in to see your library'), findsOneWidget);
    expect(find.text('Sign in'), findsOneWidget);
    expect(find.text('Liked Songs'), findsNothing);
    expect(find.byType(FloatingActionButton), findsNothing);
  });

  testWidgets('signed in shows the pinned liked songs and saved playlists', (
    tester,
  ) async {
    when(
      () => authCubit.state,
    ).thenReturn(testAccountState(isAuthenticated: true, userName: 'me'));
    when(
      () => user.savedPlaylists(
        offset: any(named: 'offset'),
        limit: any(named: 'limit'),
      ),
    ).thenAnswer(
      (_) async => PaginatedResult<Playlist>(
        items: [playlist],
        total: 1,
        offset: 0,
        limit: 20,
      ),
    );

    await tester.pumpWidget(
      buildTestableWidget(buildMockMetadataPluginCubit()),
    );
    await tester.pumpAndSettle();

    expect(find.text('Liked Songs'), findsOneWidget);
    expect(find.text('Chill Vibes'), findsOneWidget);
    expect(find.text('Playlists'), findsOneWidget);
    expect(find.text('Albums'), findsOneWidget);
    expect(find.text('Artists'), findsOneWidget);
  });

  testWidgets('signed in shows the new-playlist action on the playlists tab', (
    tester,
  ) async {
    when(
      () => authCubit.state,
    ).thenReturn(testAccountState(isAuthenticated: true, userName: 'me'));
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
        limit: 20,
      ),
    );

    await tester.pumpWidget(
      buildTestableWidget(buildMockMetadataPluginCubit()),
    );
    await tester.pumpAndSettle();

    expect(
      find.widgetWithText(FloatingActionButton, 'New playlist'),
      findsOneWidget,
    );

    await tester.tap(find.text('Albums'));
    await tester.pumpAndSettle();

    expect(
      find.widgetWithText(FloatingActionButton, 'New playlist'),
      findsNothing,
    );
  });

  testWidgets('the new-playlist action opens the create dialog', (
    tester,
  ) async {
    when(
      () => authCubit.state,
    ).thenReturn(testAccountState(isAuthenticated: true, userName: 'me'));
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
        limit: 20,
      ),
    );

    await tester.pumpWidget(
      buildTestableWidget(buildMockMetadataPluginCubit()),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.widgetWithText(FloatingActionButton, 'New playlist'));
    await tester.pumpAndSettle();

    expect(find.text('Name'), findsOneWidget);
    expect(find.text('Create'), findsOneWidget);
  });

  testWidgets('renders nothing when no plugin is loaded', (tester) async {
    await tester.pumpWidget(
      buildTestableWidget(
        buildMockMetadataPluginCubit(state: MetadataPluginNotConfiguredState()),
      ),
    );
    await tester.pumpAndSettle();

    expect(tester.takeException(), isNull);
    expect(find.text('Sign in to see your library'), findsNothing);
    expect(find.text('Liked Songs'), findsNothing);
  });
}
