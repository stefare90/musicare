import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:music_are/core/widgets/info_card.dart';

void main() {
  Widget buildTestableWidget({required InfoCard child}) {
    return MaterialApp(
      home: Scaffold(body: Center(child: child)),
    );
  }

  group('InfoCard Widget Tests', () {
    testWidgets('renders title and message with icon when provided', (
      tester,
    ) async {
      await tester.pumpWidget(
        buildTestableWidget(
          child: const InfoCard(
            icon: Icons.info_outline_rounded,
            title: 'Info Title',
            message: 'Info Message',
          ),
        ),
      );

      expect(find.text('Info Title'), findsOneWidget);
      expect(find.text('Info Message'), findsOneWidget);
      expect(find.byIcon(Icons.info_outline_rounded), findsOneWidget);
    });

    testWidgets('renders title and message without icon when icon is null', (
      tester,
    ) async {
      await tester.pumpWidget(
        buildTestableWidget(
          child: const InfoCard(
            title: 'No Content Available',
            message: 'Try refreshing',
          ),
        ),
      );

      expect(find.text('No Content Available'), findsOneWidget);
      expect(find.text('Try refreshing'), findsOneWidget);
      expect(find.byType(Icon), findsNothing);
    });

    testWidgets('renders action button and triggers callback on tap', (
      tester,
    ) async {
      bool actionTriggered = false;

      await tester.pumpWidget(
        buildTestableWidget(
          child: InfoCard(
            title: 'Info Title',
            actionLabel: 'Click Me',
            onAction: () => actionTriggered = true,
          ),
        ),
      );

      expect(find.widgetWithText(ElevatedButton, 'Click Me'), findsOneWidget);

      await tester.tap(find.widgetWithText(ElevatedButton, 'Click Me'));
      await tester.pumpAndSettle();

      expect(actionTriggered, isTrue);
    });
  });
}
