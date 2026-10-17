import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:music_are/core/l10n/app_localizations.dart';
import 'package:music_are/features/settings/presentation/pages/about_page.dart';
import 'package:musicare_audio_host_sdk/musicare_audio_host_sdk.dart' as audio_sdk;
import 'package:musicare_metadata_host_sdk/musicare_metadata_host_sdk.dart'
    as metadata_sdk;
import 'package:package_info_plus/package_info_plus.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    PackageInfo.setMockInitialValues(
      appName: 'MusicAre',
      packageName: 'com.example.music_are',
      version: '1.2.3',
      buildNumber: '7',
      buildSignature: '',
    );
  });

  testWidgets('shows app and host SDK versions', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: const AboutPage(),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('About MusicAre'), findsOneWidget);
    expect(find.text('v1.2.3 (7)'), findsOneWidget);
    expect(find.text(metadata_sdk.packageVersion), findsOneWidget);
    expect(find.text(audio_sdk.packageVersion), findsOneWidget);
  });
}
