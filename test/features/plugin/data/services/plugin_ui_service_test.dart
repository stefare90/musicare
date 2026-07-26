import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:gyawun_metadata_sdk/metadata/models/form_input_field.dart';
import 'package:music_are/features/plugin/data/services/plugin_ui_service.dart';

void main() {
  group('PluginUiService Widget Integration Tests', () {
    late GlobalKey<NavigatorState> navigatorKey;
    late PluginUiService uiService;

    setUp(() {
      navigatorKey = GlobalKey<NavigatorState>();
      uiService = PluginUiService(navigatorKey: navigatorKey);
    });

    Widget buildTestableApp({required VoidCallback onOpenForm}) {
      return MaterialApp(
        navigatorKey: navigatorKey,
        home: Scaffold(
          body: Center(
            child: ElevatedButton(
              onPressed: onOpenForm,
              child: const Text('Open Form'),
            ),
          ),
        ),
      );
    }

    testWidgets(
      'showForm renders fields correctly and returns input map on submit',
      (WidgetTester tester) async {
        Map<String, String>? formResult;

        await tester.pumpWidget(
          buildTestableApp(
            onOpenForm: () async {
              formResult = await uiService.showForm(
                title: 'MusicBrainz Auth',
                message: 'Enter your access token',
                fields: [
                  FormInputField(
                    id: 'token',
                    label: 'User Token',
                    placeholder: 'e.g. 123456',
                    isPassword: true,
                  ),
                ],
                submitLabel: 'Save',
                cancelLabel: 'Cancel',
              );
            },
          ),
        );

        await tester.tap(find.text('Open Form'));
        await tester.pumpAndSettle();

        expect(find.text('MusicBrainz Auth'), findsOneWidget);
        expect(find.text('Enter your access token'), findsOneWidget);
        expect(find.text('User Token'), findsOneWidget);

        await tester.enterText(
          find.byType(TextFormField),
          'my_secret_token_123',
        );
        await tester.pumpAndSettle();

        await tester.tap(find.text('Save'));
        await tester.pumpAndSettle();

        expect(find.text('MusicBrainz Auth'), findsNothing);
        expect(formResult, equals({'token': 'my_secret_token_123'}));
      },
    );

    testWidgets('showForm returns empty map when user taps cancel', (
      WidgetTester tester,
    ) async {
      Map<String, String>? formResult;

      await tester.pumpWidget(
        buildTestableApp(
          onOpenForm: () async {
            formResult = await uiService.showForm(
              title: 'Login',
              fields: [FormInputField(id: 'username', label: 'Username')],
              cancelLabel: 'Cancel',
            );
          },
        ),
      );

      await tester.tap(find.text('Open Form'));
      await tester.pumpAndSettle();

      await tester.tap(find.text('Cancel'));
      await tester.pumpAndSettle();

      expect(formResult, equals(<String, String>{}));
    });
  });
}
