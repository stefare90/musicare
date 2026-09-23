import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get_it/get_it.dart';
import 'package:musicare_metadata_host_sdk/musicare_metadata_host_sdk.dart';
import 'package:mocktail/mocktail.dart';
import 'package:music_are/core/l10n/app_localizations.dart';
import 'package:music_are/features/details/playlist/presentation/pages/playlist_page.dart';
import 'package:music_are/features/player/presentation/cubit/player_cubit.dart';
import 'package:music_are/features/player/presentation/cubit/player_state.dart';
import 'package:music_are/features/plugin/metadata/data/services/metadata_plugin_engine.dart';

class MockPluginEngine extends Mock implements MetadataPluginEngine {}

class MockMetadataPlugin extends Mock implements IMetadataPlugin {}

class MockPlaylistService extends Mock implements IPlaylist {}

class MockPlayerCubit extends Mock implements PlayerCubit {}

void main() {
  final sl = GetIt.instance;

  late MockPluginEngine mockEngine;
  late MockMetadataPlugin mockMetadata;
  late MockPlaylistService mockPlaylist;
  late MockPlayerCubit mockPlayerCubit;

  final testPlaylist = Playlist(
    id: 'pl1',
    name: 'Top 50 Hits',
    description: 'Best songs',
    externalUri: '',
    owner: User(id: 'u1', name: 'Spotify', externalUri: ''),
  );

  setUp(() async {
    await sl.reset();

    mockEngine = MockPluginEngine();
    mockMetadata = MockMetadataPlugin();
    mockPlaylist = MockPlaylistService();
    mockPlayerCubit = MockPlayerCubit();

    when(() => mockPlayerCubit.state).thenReturn(const PlayerState());
    when(() => mockPlayerCubit.stream).thenAnswer((_) => const Stream.empty());

    sl.registerLazySingleton<MetadataPluginEngine>(() => mockEngine);

    when(() => mockEngine.hasMetadata).thenReturn(true);
    when(() => mockEngine.metadata).thenReturn(mockMetadata);
    when(() => mockMetadata.playlist).thenReturn(mockPlaylist);
  });

  Widget buildTestableWidget() {
    return MaterialApp(
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      home: BlocProvider<PlayerCubit>.value(
        value: mockPlayerCubit,
        child: PlaylistPage(playlist: testPlaylist),
      ),
    );
  }

  group('PlaylistPage Widget Tests', () {
    testWidgets('renders playlist header with title and owner', (tester) async {
      when(() => mockPlaylist.tracks('pl1', offset: 0, limit: 20)).thenAnswer(
        (_) async => PaginatedResult(items: [], total: 0, offset: 0, limit: 20),
      );

      await tester.pumpWidget(buildTestableWidget());
      await tester.pumpAndSettle();

      expect(find.text('Top 50 Hits'), findsNWidgets(2)); // Header + AppBar
      expect(find.text('Spotify'), findsOneWidget);
    });
  });
}
