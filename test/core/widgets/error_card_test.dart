import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:music_are/core/l10n/app_localizations.dart';
import 'package:music_are/core/widgets/error_card.dart';

void main() {
  Widget buildTestableWidget({required ErrorCard child}) {
    return MaterialApp(
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      home: Scaffold(body: Center(child: child)),
    );
  }

  group('ErrorCard Widget Tests', () {
    testWidgets('renders localized error message and icon', (tester) async {
      await tester.pumpWidget(
        buildTestableWidget(child: ErrorCard(error: Exception('Test Error'))),
      );

      expect(
        find.text('An unexpected error occurred: Test Error'),
        findsOneWidget,
      );
      expect(find.byIcon(Icons.error_outline_rounded), findsOneWidget);
    });

    testWidgets('renders retry button and triggers callback on tap', (
      tester,
    ) async {
      bool retryTapped = false;

      await tester.pumpWidget(
        buildTestableWidget(
          child: ErrorCard(
            error: Exception('Test Error'),
            onRetry: () => retryTapped = true,
          ),
        ),
      );

      expect(find.widgetWithText(ElevatedButton, 'Retry'), findsOneWidget);

      await tester.tap(find.widgetWithText(ElevatedButton, 'Retry'));
      await tester.pumpAndSettle();

      expect(retryTapped, isTrue);
    });
  });
}
