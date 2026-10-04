import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:music_are/core/l10n/app_localizations.dart';
import 'package:music_are/features/details/playlist/presentation/widgets/playlist_visibility_badge.dart';

void main() {
  Widget buildTestableWidget({required Widget child}) {
    return MaterialApp(
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      home: Scaffold(body: Center(child: child)),
    );
  }

  group('PlaylistVisibilityBadge Widget Tests', () {
    testWidgets('shows Public for a public playlist', (tester) async {
      await tester.pumpWidget(
        buildTestableWidget(
          child: const PlaylistVisibilityBadge(isPublic: true),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Public'), findsOneWidget);
      expect(find.byIcon(Icons.public_rounded), findsOneWidget);
      expect(find.text('Private'), findsNothing);
    });

    testWidgets('shows Private for a private playlist', (tester) async {
      await tester.pumpWidget(
        buildTestableWidget(
          child: const PlaylistVisibilityBadge(isPublic: false),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Private'), findsOneWidget);
      expect(find.byIcon(Icons.lock_outline_rounded), findsOneWidget);
      expect(find.text('Public'), findsNothing);
    });

    testWidgets('renders nothing when visibility is unknown', (tester) async {
      await tester.pumpWidget(
        buildTestableWidget(
          child: const PlaylistVisibilityBadge(isPublic: null),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Public'), findsNothing);
      expect(find.text('Private'), findsNothing);
      expect(find.byIcon(Icons.public_rounded), findsNothing);
      expect(find.byIcon(Icons.lock_outline_rounded), findsNothing);
    });
  });
}
