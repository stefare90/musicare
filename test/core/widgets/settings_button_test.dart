import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:music_are/core/l10n/app_localizations.dart';
import 'package:music_are/core/widgets/settings_button.dart';

void main() {
  testWidgets('renders the settings gear', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: Scaffold(appBar: AppBar(actions: const [SettingsButton()])),
      ),
    );

    expect(find.byIcon(Icons.settings_outlined), findsOneWidget);
    expect(find.byType(IconButton), findsOneWidget);
  });
}
