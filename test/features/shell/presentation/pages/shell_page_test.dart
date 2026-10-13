import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../helpers/metadata_plugin_test_helpers.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:musicare_metadata_host_sdk/musicare_metadata_host_sdk.dart';
import 'package:mocktail/mocktail.dart';
import 'package:music_are/core/l10n/app_localizations.dart';
import 'package:music_are/features/plugin/metadata/presentation/cubit/user_cubit.dart';
import 'package:music_are/features/player/presentation/cubit/player_cubit.dart';
import 'package:music_are/features/player/presentation/cubit/player_state.dart';
import 'package:music_are/features/player/presentation/cubit/queue_state.dart';
import 'package:music_are/features/player/presentation/pages/full_player_page.dart';
import 'package:music_are/features/player/presentation/widgets/mini_player.dart';
import 'package:music_are/features/plugin/metadata/data/services/metadata_plugin_engine.dart';
import 'package:music_are/features/shell/presentation/pages/shell_page.dart';

class MockPlayerCubit extends Mock implements PlayerCubit {}

class MockPluginEngine extends Mock implements MetadataPluginEngine {}

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
  final testTrack = createTestTrack('t1', 'Come Together');

  setUp(() {
    mockPlayerCubit = MockPlayerCubit();
    when(() => mockPlayerCubit.state).thenReturn(const PlayerState());
    when(() => mockPlayerCubit.stream).thenAnswer((_) => const Stream.empty());
  });

  GoRouter createTestRouter({double keyboardHeight = 0}) {
    return GoRouter(
      initialLocation: '/',
      routes: [
        StatefulShellRoute.indexedStack(
          builder: (context, state, navigationShell) {
            final media = MediaQuery.of(context);
            return MediaQuery(
              data: media.copyWith(
                viewInsets: EdgeInsets.only(bottom: keyboardHeight),
              ),
              child: ShellPage(navigationShell: navigationShell),
            );
          },
          branches: [
            StatefulShellBranch(
              routes: [
                GoRoute(
                  path: '/',
                  builder: (context, state) => const Scaffold(
                    body: Center(child: Text('Home Screen Content')),
                  ),
                  routes: [
                    GoRoute(
                      path: 'album',
                      builder: (context, state) => const Scaffold(
                        body: Center(child: Text('Album Screen Content')),
                      ),
                    ),
                    GoRoute(
                      path: 'artist',
                      builder: (context, state) => const Scaffold(
                        body: Center(child: Text('Artist Screen Content')),
                      ),
                    ),
                  ],
                ),
              ],
            ),
            StatefulShellBranch(
              routes: [
                GoRoute(
                  path: '/search',
                  builder: (context, state) => const Scaffold(
                    body: Center(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text('Search Screen Content'),
                          TextField(),
                        ],
                      ),
                    ),
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

  Widget buildTestableWidget({double keyboardHeight = 0}) {
    final engine = MockPluginEngine();
    when(() => engine.hasMetadata).thenReturn(false);
    return MultiBlocProvider(
      providers: [
        BlocProvider<PlayerCubit>.value(value: mockPlayerCubit),
        BlocProvider<UserCubit>(
          create: (_) => TestUserCubit(testUserState()),
        ),
      ],
      child: MaterialApp.router(
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        routerConfig: createTestRouter(keyboardHeight: keyboardHeight),
      ),
    );
  }

  group('ShellPage Widget Tests', () {
    testWidgets('renders NavigationBar and initial branch when no track is active', (
      tester,
    ) async {
      await tester.pumpWidget(buildTestableWidget());
      await tester.pumpAndSettle();

      expect(find.byType(MiniPlayer), findsNothing);
      expect(find.text('Home Screen Content'), findsOneWidget);
      expect(find.text('Home'), findsOneWidget);
      expect(find.text('Search'), findsOneWidget);
      expect(find.text('Library'), findsOneWidget);
    });

    testWidgets('renders MiniPlayer when track is active in queue', (
      tester,
    ) async {
      when(() => mockPlayerCubit.state).thenReturn(
        PlayerState(queue: QueueState(tracks: [testTrack])),
      );

      await tester.pumpWidget(buildTestableWidget());
      await tester.pumpAndSettle();

      expect(find.byType(MiniPlayer), findsOneWidget);
      expect(find.text('Come Together'), findsOneWidget);
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
      'tapping MiniPlayer expands sliding panel to FullPlayerPage', 
      (tester) async {
        when(() => mockPlayerCubit.state).thenReturn(
          PlayerState(queue: QueueState(tracks: [testTrack])),
        );

        await tester.pumpWidget(buildTestableWidget());
        await tester.pumpAndSettle();

        expect(find.byType(FullPlayerPage), findsNothing);

        await tester.tap(find.byType(MiniPlayer));
        await tester.pumpAndSettle();

        expect(find.byType(FullPlayerPage), findsOneWidget);
      },
    );

    testWidgets(
      'swiping up on MiniPlayer expands sliding panel to FullPlayerPage and collapse button closes it',
      (tester) async {
        when(() => mockPlayerCubit.state).thenReturn(
          PlayerState(queue: QueueState(tracks: [testTrack])),
        );

        await tester.pumpWidget(buildTestableWidget());
        await tester.pumpAndSettle();

        expect(find.text('Come Together'), findsOneWidget);

        await tester.fling(
          find.byType(MiniPlayer),
          const Offset(0, -600),
          1000,
        );
        await tester.pumpAndSettle();

        expect(find.byType(FullPlayerPage), findsOneWidget);

        await tester.tap(find.byIcon(Icons.keyboard_arrow_down_rounded));
        await tester.pumpAndSettle();

        expect(find.byType(FullPlayerPage), findsNothing);
        expect(find.byType(MiniPlayer), findsOneWidget);
      },
    );

    testWidgets(
      'dragging down on FullPlayerPage collapses panel back to MiniPlayer',
      (tester) async {
        when(() => mockPlayerCubit.state).thenReturn(
          PlayerState(queue: QueueState(tracks: [testTrack])),
        );

        await tester.pumpWidget(buildTestableWidget());
        await tester.pumpAndSettle();

        await tester.tap(find.byType(MiniPlayer));
        await tester.pumpAndSettle();
        expect(find.byType(FullPlayerPage), findsOneWidget);

        await tester.fling(
          find.byType(FullPlayerPage),
          const Offset(0, 600),
          1000,
        );
        await tester.pumpAndSettle();

        expect(find.byType(FullPlayerPage), findsNothing);
        expect(find.byType(MiniPlayer), findsOneWidget);
      },
    );

    testWidgets(
      'system back button via BackButtonListener collapses FullPlayerPage without popping route',
      (tester) async {
        when(() => mockPlayerCubit.state).thenReturn(
          PlayerState(queue: QueueState(tracks: [testTrack])),
        );

        await tester.pumpWidget(buildTestableWidget());
        await tester.pumpAndSettle();

        await tester.tap(find.byType(MiniPlayer));
        await tester.pumpAndSettle();
        expect(find.byType(FullPlayerPage), findsOneWidget);

        final backHandled = await tester.binding.handlePopRoute();
        expect(backHandled, isTrue);
        await tester.pumpAndSettle();

        expect(find.byType(FullPlayerPage), findsNothing);
        expect(find.text('Home Screen Content'), findsOneWidget);
      },
    );
    testWidgets(
      'expanding the player dismisses the search keyboard, and a modal opened '
      'from the player does not restore it',
      (tester) async {
        when(() => mockPlayerCubit.state).thenReturn(
          PlayerState(queue: QueueState(tracks: [testTrack])),
        );

        await tester.pumpWidget(buildTestableWidget());
        await tester.pumpAndSettle();

        await tester.tap(find.text('Search'));
        await tester.pumpAndSettle();
        await tester.tap(find.byType(TextField));
        await tester.pumpAndSettle();
        expect(tester.testTextInput.isVisible, isTrue);

        await tester.tap(find.byType(MiniPlayer));
        await tester.pumpAndSettle();
        expect(find.byType(FullPlayerPage), findsOneWidget);
        expect(tester.testTextInput.isVisible, isFalse);

        final playerContext = tester.element(find.byType(FullPlayerPage));
        unawaited(
          showModalBottomSheet<void>(
            context: playerContext,
            builder: (_) => const SizedBox(height: 100),
          ),
        );
        await tester.pumpAndSettle();
        expect(tester.testTextInput.isVisible, isFalse);

        Navigator.of(playerContext).pop();
        await tester.pumpAndSettle();

        expect(tester.testTextInput.isVisible, isFalse);
      },
    );

    testWidgets(
      'going to the album from the player options lowers the panel',
      (tester) async {
        when(() => mockPlayerCubit.state).thenReturn(
          PlayerState(queue: QueueState(tracks: [testTrack])),
        );

        await tester.pumpWidget(buildTestableWidget());
        await tester.pumpAndSettle();

        await tester.tap(find.byType(MiniPlayer));
        await tester.pumpAndSettle();
        expect(find.byType(FullPlayerPage), findsOneWidget);

        await tester.tap(find.byIcon(Icons.more_vert_rounded));
        await tester.pumpAndSettle();
        await tester.tap(find.text('Go to Album'));
        await tester.pumpAndSettle();

        expect(find.byType(FullPlayerPage), findsNothing);
        expect(find.byType(MiniPlayer), findsOneWidget);
        expect(
          find.text('Album Screen Content').hitTestable(),
          findsOneWidget,
        );
      },
    );

    testWidgets(
      'keyboard does not lift the navigation bar or the mini player',
      (tester) async {
        when(() => mockPlayerCubit.state).thenReturn(
          PlayerState(queue: QueueState(tracks: [testTrack])),
        );

        await tester.pumpWidget(buildTestableWidget(keyboardHeight: 400));
        await tester.pumpAndSettle();

        final screenHeight = tester.view.physicalSize.height /
            tester.view.devicePixelRatio;
        final navRect = tester.getRect(find.byType(NavigationBar));
        final miniRect = tester.getRect(find.byType(MiniPlayer));
        expect(navRect.bottom, moreOrLessEquals(screenHeight));
        expect(miniRect.bottom, moreOrLessEquals(navRect.top));
      },
    );

    testWidgets(
      'going to the artist from the player options lowers the panel',
      (tester) async {
        when(() => mockPlayerCubit.state).thenReturn(
          PlayerState(queue: QueueState(tracks: [testTrack])),
        );

        await tester.pumpWidget(buildTestableWidget());
        await tester.pumpAndSettle();

        await tester.tap(find.byType(MiniPlayer));
        await tester.pumpAndSettle();
        expect(find.byType(FullPlayerPage), findsOneWidget);

        await tester.tap(find.byIcon(Icons.more_vert_rounded));
        await tester.pumpAndSettle();
        await tester.drag(find.text('Share Track'), const Offset(0, -300));
        await tester.pumpAndSettle();
        await tester.tap(find.text('Go to Artist'));
        await tester.pumpAndSettle();

        expect(find.byType(FullPlayerPage), findsNothing);
        expect(find.byType(MiniPlayer), findsOneWidget);
        expect(
          find.text('Artist Screen Content').hitTestable(),
          findsOneWidget,
        );
      },
    );
  });
}
