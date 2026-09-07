import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:music_are/core/l10n/app_localizations.dart';
import 'package:music_are/core/widgets/error_tile.dart';

void main() {
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
  });
}
