import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:music_are/core/l10n/app_localizations.dart';
import 'package:music_are/features/plugin/metadata/presentation/metadata_auth_presenter.dart';
import 'package:music_are/features/plugin/shared/data/exceptions/plugin_exceptions.dart';
import 'package:musicare_metadata_host_sdk/musicare_metadata_host_sdk.dart';

void main() {
  group('MetadataAuthPresenterImpl', () {
    late GlobalKey<NavigatorState> navigatorKey;
    late MetadataAuthPresenterImpl presenter;

    const fields = [
      FormInputField(id: 'token', label: 'Token', isPassword: true),
    ];

    setUp(() {
      navigatorKey = GlobalKey<NavigatorState>();
      presenter = MetadataAuthPresenterImpl(navigatorKey: navigatorKey);
    });

    Future<void> pumpApp(WidgetTester tester) => tester.pumpWidget(
      MaterialApp(
        navigatorKey: navigatorKey,
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: const Scaffold(body: SizedBox.shrink()),
      ),
    );

    testWidgets('promptForm returns the typed values on submit', (tester) async {
      await pumpApp(tester);

      final result = presenter.promptForm(fields);
      await tester.pumpAndSettle();

      expect(find.text('Sign in'), findsNWidgets(2));
      await tester.enterText(find.byType(TextFormField), 'secret');
      await tester.tap(find.text('Sign in').last);
      await tester.pumpAndSettle();

      expect(await result, equals({'token': 'secret'}));
    });

    testWidgets('promptForm returns null when the user cancels', (tester) async {
      await pumpApp(tester);

      final result = presenter.promptForm(fields);
      await tester.pumpAndSettle();

      await tester.tap(find.text('Cancel'));
      await tester.pumpAndSettle();

      expect(await result, isNull);
    });

    testWidgets('promptForm throws PluginErrorNoContext without a navigator', (
      tester,
    ) async {
      await expectLater(
        presenter.promptForm(fields),
        throwsA(isA<PluginErrorNoContext>()),
      );
    });

    test('openBrowser throws UnsupportedError explaining what is missing', () {
      expect(
        () => presenter.openBrowser('https://example.com/oauth'),
        throwsA(isA<UnsupportedError>()),
      );
    });
  });
}
