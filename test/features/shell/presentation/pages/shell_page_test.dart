import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:mocktail/mocktail.dart';
import 'package:music_are/core/l10n/app_localizations.dart';
import 'package:music_are/features/player/presentation/cubit/player_cubit.dart';
import 'package:music_are/features/player/presentation/cubit/player_state.dart';
import 'package:music_are/features/player/presentation/widgets/mini_player.dart';
import 'package:music_are/features/shell/presentation/pages/shell_page.dart';

class MockPlayerCubit extends Mock implements PlayerCubit {}

void main() {
  late MockPlayerCubit mockPlayerCubit;

  setUp(() {
    mockPlayerCubit = MockPlayerCubit();
    when(() => mockPlayerCubit.state).thenReturn(const PlayerState());
    when(() => mockPlayerCubit.stream).thenAnswer((_) => const Stream.empty());
  });

  /// Helper to create a test GoRouter with StatefulShellRoute
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
  });
}
