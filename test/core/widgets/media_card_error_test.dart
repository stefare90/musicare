import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:music_are/core/l10n/app_localizations.dart';
import 'package:music_are/core/widgets/media/media_card_error.dart';
import 'package:music_are/core/widgets/media/media_card_metrics.dart';

void main() {
  Widget buildTestableWidget({required Widget child}) {
    return MaterialApp(
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      home: Scaffold(body: Center(child: child)),
    );
  }

  group('MediaCardError Widget Tests', () {
    testWidgets('renders title and triggers retry callback on tap', (
      tester,
    ) async {
      bool retried = false;

      await tester.pumpWidget(
        buildTestableWidget(
          child: MediaCardError(
            width: MediaCardMetrics.rowCardWidth,
            title: 'Related Artists',
            error: Exception('Network timeout'),
            onRetry: () => retried = true,
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Related Artists'), findsOneWidget);
      expect(find.byIcon(Icons.warning_amber_rounded), findsOneWidget);

      await tester.tap(find.byIcon(Icons.refresh_rounded));
      await tester.pumpAndSettle();

      expect(retried, isTrue);
    });
  });
}
