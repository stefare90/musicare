import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:music_are/core/l10n/app_localizations.dart';
import 'package:music_are/features/plugin/shared/data/models/plugin_type.dart';
import 'package:music_are/features/plugin/shared/presentation/utils/plugin_type_localizer.dart';

void main() {
  testWidgets('PluginTypeLocalizer translates correctly', (tester) async {
    late BuildContext ctx;
    await tester.pumpWidget(
      MaterialApp(
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: Builder(
          builder: (context) {
            ctx = context;
            return const SizedBox.shrink();
          },
        ),
      ),
    );

    expect(PluginType.metadata.toLocalizedString(ctx), equals('Metadata'));
    expect(
      PluginType.audioSource.toLocalizedString(ctx),
      equals('Audio source'),
    );
  });
}
