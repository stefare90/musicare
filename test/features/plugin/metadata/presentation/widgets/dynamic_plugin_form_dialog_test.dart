import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:music_are/core/l10n/app_localizations.dart';
import 'package:music_are/features/plugin/metadata/presentation/widgets/dynamic_plugin_form_dialog.dart';
import 'package:musicare_metadata_host_sdk/musicare_metadata_host_sdk.dart';

void main() {
  Future<void> pumpDialog(
    WidgetTester tester, {
    String? message,
    required List<FormInputField> fields,
    Future<bool> Function(String url)? onHelpTap,
  }) => tester.pumpWidget(
    MaterialApp(
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      home: Scaffold(
        body: DynamicPluginFormDialog(
          title: 'Connect to ListenBrainz',
          message: message,
          fields: fields,
          submitLabel: 'Sign in',
          cancelLabel: 'Cancel',
          onHelpTap: onHelpTap,
        ),
      ),
    ),
  );

  const tokenField = FormInputField(
    id: 'token',
    label: 'Token',
    isPassword: true,
    helpUrl: 'https://listenbrainz.org/profile/',
  );

  testWidgets('renders the title, the message and the fields', (tester) async {
    await pumpDialog(
      tester,
      message: 'Paste the personal token from your ListenBrainz profile.',
      fields: const [tokenField],
    );

    expect(find.text('Connect to ListenBrainz'), findsOneWidget);
    expect(
      find.text('Paste the personal token from your ListenBrainz profile.'),
      findsOneWidget,
    );
    expect(find.text('Token'), findsOneWidget);
  });

  testWidgets('shows the help action and forwards the url to onHelpTap', (
    tester,
  ) async {
    String? tapped;
    await pumpDialog(
      tester,
      fields: const [tokenField],
      onHelpTap: (url) async {
        tapped = url;
        return true;
      },
    );

    expect(find.text('Where do I find it?'), findsOneWidget);
    await tester.tap(find.text('Where do I find it?'));
    await tester.pumpAndSettle();

    expect(tapped, 'https://listenbrainz.org/profile/');
  });

  testWidgets('hides the help action without a helpUrl', (tester) async {
    await pumpDialog(
      tester,
      fields: const [
        FormInputField(id: 'token', label: 'Token', isPassword: true),
      ],
      onHelpTap: (_) async => true,
    );

    expect(find.text('Where do I find it?'), findsNothing);
  });

  testWidgets('shows a snackbar when the help link cannot be opened', (
    tester,
  ) async {
    await pumpDialog(
      tester,
      fields: const [tokenField],
      onHelpTap: (_) async => false,
    );

    await tester.tap(find.text('Where do I find it?'));
    await tester.pumpAndSettle();

    expect(
      find.text('Could not open the link. Please try again.'),
      findsOneWidget,
    );
  });
}
