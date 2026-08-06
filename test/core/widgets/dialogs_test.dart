import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:music_are/core/widgets/dialogs.dart';

void main() {
  Widget buildTestableApp({required Widget body}) {
    return MaterialApp(home: Scaffold(body: body));
  }

  group('Dialogs Widget Tests', () {
    testWidgets('showLoading displays dialog and hide closes it', (
      tester,
    ) async {
      await tester.pumpWidget(
        buildTestableApp(
          body: Builder(
            builder: (context) => ElevatedButton(
              onPressed: () {
                Dialogs.showLoading(context, message: 'Loading test...');
              },
              child: const Text('Show Loading'),
            ),
          ),
        ),
      );

      await tester.tap(find.text('Show Loading'));
      await tester.pump();
      expect(find.text('Loading test...'), findsOneWidget);
      expect(find.byType(CircularProgressIndicator), findsOneWidget);

      final BuildContext context = tester.element(find.text('Loading test...'));
      Dialogs.hide(context);
      await tester.pumpAndSettle();

      expect(find.text('Loading test...'), findsNothing);
    });

    testWidgets('confirm dialog returns true on confirm button tap', (
      tester,
    ) async {
      bool? confirmResult;

      await tester.pumpWidget(
        buildTestableApp(
          body: Builder(
            builder: (context) => ElevatedButton(
              onPressed: () async {
                confirmResult = await Dialogs.confirm(
                  context,
                  title: 'Delete Item',
                  message: 'Are you sure?',
                  confirmLabel: 'Yes',
                  cancelLabel: 'No',
                );
              },
              child: const Text('Open Confirm'),
            ),
          ),
        ),
      );

      await tester.tap(find.text('Open Confirm'));
      await tester.pumpAndSettle();

      expect(find.text('Delete Item'), findsOneWidget);
      expect(find.text('Are you sure?'), findsOneWidget);

      await tester.tap(find.text('Yes'));
      await tester.pumpAndSettle();

      expect(confirmResult, isTrue);
    });

    testWidgets('showErrorSnackBar displays SnackBar with error icon', (
      tester,
    ) async {
      await tester.pumpWidget(
        buildTestableApp(
          body: Builder(
            builder: (context) => ElevatedButton(
              onPressed: () {
                Dialogs.showErrorSnackBar(context, message: 'Network failed');
              },
              child: const Text('Show Error'),
            ),
          ),
        ),
      );

      await tester.tap(find.text('Show Error'));
      await tester.pumpAndSettle();

      expect(find.byType(SnackBar), findsOneWidget);
      expect(find.text('Network failed'), findsOneWidget);
      expect(find.byIcon(Icons.error_outline_rounded), findsOneWidget);
    });
  });
}
