import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:music_are/core/l10n/app_localizations.dart';
import 'package:music_are/features/plugin/metadata/presentation/services/metadata_auth_presenter.dart';
import 'package:music_are/features/plugin/shared/data/exceptions/plugin_exceptions.dart';
import 'package:musicare_metadata_host_sdk/musicare_metadata_host_sdk.dart';
import 'package:plugin_platform_interface/plugin_platform_interface.dart';
import 'package:url_launcher_platform_interface/url_launcher_platform_interface.dart';

class FakeUrlLauncher extends Fake
    with MockPlatformInterfaceMixin
    implements UrlLauncherPlatform {
  FakeUrlLauncher({this.result = true});

  final bool result;
  final List<String> launched = [];

  @override
  Future<bool> launchUrl(String url, LaunchOptions options) async {
    launched.add(url);
    return result;
  }
}

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

      final result = presenter.promptForm(fields: fields);
      await tester.pumpAndSettle();

      expect(find.text('Sign in'), findsNWidgets(2));
      await tester.enterText(find.byType(TextFormField), 'secret');
      await tester.tap(find.text('Sign in').last);
      await tester.pumpAndSettle();

      expect(await result, equals({'token': 'secret'}));
    });

    testWidgets('promptForm returns null when the user cancels', (tester) async {
      await pumpApp(tester);

      final result = presenter.promptForm(fields: fields);
      await tester.pumpAndSettle();

      await tester.tap(find.text('Cancel'));
      await tester.pumpAndSettle();

      expect(await result, isNull);
    });

    testWidgets('promptForm shows the plugin-provided title and message verbatim', (
      tester,
    ) async {
      await pumpApp(tester);

      final result = presenter.promptForm(
        title: 'Connect to ListenBrainz',
        message: 'Paste the personal token from your ListenBrainz profile.',
        fields: fields,
      );
      await tester.pumpAndSettle();

      expect(find.text('Connect to ListenBrainz'), findsOneWidget);
      expect(
        find.text('Paste the personal token from your ListenBrainz profile.'),
        findsOneWidget,
      );
      expect(find.text('Sign in'), findsOneWidget);

      unawaited(result);
    });

    testWidgets('promptForm falls back to the localized title', (tester) async {
      await pumpApp(tester);

      final result = presenter.promptForm(fields: fields);
      await tester.pumpAndSettle();

      expect(find.text('Sign in'), findsNWidgets(2));

      unawaited(result);
    });

    testWidgets('promptForm throws PluginErrorNoContext without a navigator', (
      tester,
    ) async {
      await expectLater(
        presenter.promptForm(fields: fields),
        throwsA(isA<PluginErrorNoContext>()),
      );
    });

    testWidgets('the help action opens the field helpUrl', (tester) async {
      final launcher = FakeUrlLauncher();
      UrlLauncherPlatform.instance = launcher;
      addTearDown(() => UrlLauncherPlatform.instance = FakeUrlLauncher());

      const helpFields = [
        FormInputField(
          id: 'token',
          label: 'Token',
          isPassword: true,
          helpUrl: 'https://listenbrainz.org/profile/',
        ),
      ];

      await pumpApp(tester);
      final result = presenter.promptForm(fields: helpFields);
      await tester.pumpAndSettle();

      await tester.tap(find.text('Where do I find it?'));
      await tester.pumpAndSettle();

      expect(launcher.launched, ['https://listenbrainz.org/profile/']);

      unawaited(result);
    });

    test('openBrowser launches the url in an external application', () async {
      final launcher = FakeUrlLauncher();
      UrlLauncherPlatform.instance = launcher;

      await presenter.openBrowser('https://listenbrainz.org/profile/');

      expect(launcher.launched, ['https://listenbrainz.org/profile/']);
    });

    test('openBrowser throws UnsupportedError when the platform refuses', () async {
      UrlLauncherPlatform.instance = FakeUrlLauncher(result: false);

      await expectLater(
        presenter.openBrowser('https://listenbrainz.org/profile/'),
        throwsA(isA<UnsupportedError>()),
      );
    });

    test('openBrowser throws UnsupportedError for a malformed url', () async {
      UrlLauncherPlatform.instance = FakeUrlLauncher();

      await expectLater(
        presenter.openBrowser('not a url'),
        throwsA(isA<UnsupportedError>()),
      );
    });
  });
}
