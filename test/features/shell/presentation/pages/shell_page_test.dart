import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:gyawun_metadata_sdk/metadata/models/album.dart';
import 'package:gyawun_metadata_sdk/metadata/models/artist.dart';
import 'package:gyawun_metadata_sdk/metadata/models/track.dart';
import 'package:mocktail/mocktail.dart';
import 'package:music_are/core/l10n/app_localizations.dart';
import 'package:music_are/features/player/presentation/cubit/player_cubit.dart';
import 'package:music_are/features/player/presentation/cubit/player_state.dart';
import 'package:music_are/features/player/presentation/cubit/queue_state.dart';
import 'package:music_are/features/player/presentation/pages/full_player_page.dart';
import 'package:music_are/features/player/presentation/widgets/mini_player.dart';
import 'package:music_are/features/shell/presentation/pages/shell_page.dart';

class MockPlayerCubit extends Mock implements PlayerCubit {}

Track createTestTrack(String id, String name) {
  return Track(
    id: id,
    name: name,
    externalUri: '',
    artists: [Artist(id: 'a1', name: 'The Beatles', externalUri: '')],
    album: Album(
      id: 'al1',
      name: 'Abbey Road',
      artists: [],
      releaseDate: '',
      externalUri: '',
      totalTracks: 1,
      albumType: AlbumType.album,
    ),
    durationMs: 200000,
  );
}

void main() {
  late MockPlayerCubit mockPlayerCubit;

  setUp(() {
    mockPlayerCubit = MockPlayerCubit();
    when(() => mockPlayerCubit.state).thenReturn(const PlayerState());
    when(() => mockPlayerCubit.stream).thenAnswer((_) => const Stream.empty());
  });

  GoRouter createTestRouter() {
    return GoRouter(
      initialLocation: '/',
      routes: [
        StatefulShellRoute.indexedStack(
          builder: (context, state, navigationShell) {
            return ShellPage(navigationShell: navigationShell);
          },
          branches: [
            StatefulShellBranch(
              routes: [
                GoRoute(
                  path: '/',
                  builder: (context, state) => const Scaffold(
                    body: Center(child: Text('Home Screen Content')),
                  ),
                ),
              ],
            ),
            StatefulShellBranch(
              routes: [
                GoRoute(
                  path: '/search',
                  builder: (context, state) => const Scaffold(
                    body: Center(child: Text('Search Screen Content')),
                  ),
                ),
              ],
            ),
            StatefulShellBranch(
              routes: [
                GoRoute(
                  path: '/library',
                  builder: (context, state) => const Scaffold(
                    body: Center(child: Text('Library Screen Content')),
                  ),
                ),
              ],
            ),
          ],
        ),
      ],
    );
  }

  Widget buildTestableWidget() {
    return BlocProvider<PlayerCubit>.value(
      value: mockPlayerCubit,
      child: MaterialApp.router(
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        routerConfig: createTestRouter(),
      ),
    );
  }

  group('ShellPage Widget Tests', () {
    testWidgets('renders MiniPlayer and NavigationBar with initial branch', (
      tester,
    ) async {
      await tester.pumpWidget(buildTestableWidget());
      await tester.pumpAndSettle();

      expect(find.byType(MiniPlayer), findsOneWidget);
      expect(find.text('Home Screen Content'), findsOneWidget);

      expect(find.text('Home'), findsOneWidget);
      expect(find.text('Search'), findsOneWidget);
      expect(find.text('Library'), findsOneWidget);
    });

    testWidgets(
      'switches branch screen content when navigation destination is tapped',
      (tester) async {
        await tester.pumpWidget(buildTestableWidget());
        await tester.pumpAndSettle();

        expect(find.text('Home Screen Content'), findsOneWidget);

        await tester.tap(find.text('Search'));
        await tester.pumpAndSettle();

        expect(find.text('Search Screen Content'), findsOneWidget);
        expect(find.text('Home Screen Content'), findsNothing);

        await tester.tap(find.text('Library'));
        await tester.pumpAndSettle();

        expect(find.text('Library Screen Content'), findsOneWidget);
      },
    );

    testWidgets(
      'drags up miniplayer frame-by-frame into full player and collapses back',
      (tester) async {
        final testTrack = createTestTrack('t1', 'Come Together');
        when(() => mockPlayerCubit.state).thenReturn(
          PlayerState(queue: QueueState(tracks: [testTrack])),
        );

        await tester.pumpWidget(buildTestableWidget());
        await tester.pumpAndSettle();

        expect(find.text('Come Together'), findsOneWidget);

        // Swipe verso l'alto per aprire il full player
        await tester.fling(
          find.byType(MiniPlayer),
          const Offset(0, -600),
          1000,
        );
        await tester.pumpAndSettle();

        // FullPlayerPage è ora visibile ed espanso
        expect(find.byType(FullPlayerPage), findsOneWidget);

        // Tap sul pulsante di chiusura (freccia in basso)
        await tester.tap(find.byIcon(Icons.keyboard_arrow_down_rounded));
        await tester.pumpAndSettle();

        expect(find.text('Come Together'), findsOneWidget);
      },
    );

    testWidgets(
      'snaps to full player when dragged up past 25% threshold',
      (tester) async {
        final testTrack = createTestTrack('t1', 'Come Together');
        when(() => mockPlayerCubit.state).thenReturn(
          PlayerState(queue: QueueState(tracks: [testTrack])),
        );

        await tester.pumpWidget(buildTestableWidget());
        await tester.pumpAndSettle();

        // Trascina verso l'alto lentamente superando la soglia del 25%
        await tester.drag(find.byType(MiniPlayer), const Offset(0, -250));
        await tester.pumpAndSettle();

        expect(find.byType(FullPlayerPage), findsOneWidget);
      },
    );
  });
}
