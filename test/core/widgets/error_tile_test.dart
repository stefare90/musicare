import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:music_are/core/l10n/app_localizations.dart';
import 'package:music_are/core/widgets/error_tile.dart';

import '../../helpers/error_presentation_test_helpers.dart';

void main() {
  setUp(registerTestErrorPresentation);
  Widget buildTestableWidget({required Widget child}) {
    return MaterialApp(
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      home: Scaffold(body: child),
    );
  }

  group('ErrorTile Widget Tests', () {
    testWidgets('renders title, error message, and triggers onRetry', (
      tester,
    ) async {
      bool retryPressed = false;

      await tester.pumpWidget(
        buildTestableWidget(
          child: ErrorTile(
            title: 'Top Tracks',
            error: Exception('Custom error'),
            onRetry: () => retryPressed = true,
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Top Tracks'), findsOneWidget);
      expect(
        find.text('An unexpected error occurred: Custom error'),
        findsOneWidget,
      );

      await tester.tap(find.byIcon(Icons.refresh_rounded));
      await tester.pumpAndSettle();

      expect(retryPressed, isTrue);
    });

    testWidgets('wraps a long provider cause instead of truncating it', (
      tester,
    ) async {
      tester.view.physicalSize = const Size(320, 800);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.reset);

      const cause =
          'ListenBrainz rejected the token (HTTP 401): your MetaBrainz '
          'account does not have a verified email address. Verify it in your '
          'profile and sign in again.';
      await tester.pumpWidget(
        buildTestableWidget(
          child: ErrorTile(
            title: 'Popular Tracks',
            error: Exception(cause),
          ),
        ),
      );
      await tester.pumpAndSettle();

      final paragraph = tester.renderObject<RenderParagraph>(
        find.text('An unexpected error occurred: $cause'),
      );
      expect(paragraph.didExceedMaxLines, isFalse);

      final text = paragraph.text.toPlainText();
      final lines = paragraph
          .getBoxesForSelection(
            TextSelection(baseOffset: 0, extentOffset: text.length),
          )
          .map((box) => box.top)
          .toSet();
      expect(lines.length, greaterThan(1));
    });
  });
}
