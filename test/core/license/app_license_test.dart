import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:music_are/core/config/app_assets.dart';
import 'package:music_are/core/config/app_info.dart';
import 'package:music_are/core/license/app_license.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('bundles the project license as an asset', () async {
    final text = await rootBundle.loadString(AppAssets.license);

    expect(text, contains('BSD 3-Clause License'));
    expect(text, contains('Copyright (c) 2026, stefare'));
  });

  test('registers the bundled license text for the license page', () async {
    AppLicense.register();

    final entries = await LicenseRegistry.licenses
        .where((entry) => entry.packages.contains(AppInfo.name))
        .toList();

    expect(entries, isNotEmpty);
    final text = entries.first.paragraphs.map((p) => p.text).join('\n');
    expect(text, contains('BSD 3-Clause License'));
    expect(text, contains('Neither the name of the copyright holder'));
  });

  testWidgets('the license page shows the bundled license first', (
    tester,
  ) async {
    LicenseRegistry.reset();
    AppLicense.register();

    await tester.pumpWidget(
      const MaterialApp(
        home: LicensePage(
          applicationName: 'MusicAre',
          applicationVersion: '1.2.3 (7)',
        ),
      ),
    );
    await tester.runAsync(
      () => Future<void>.delayed(const Duration(milliseconds: 100)),
    );
    for (var i = 0; i < 5; i++) {
      await tester.pump(const Duration(milliseconds: 200));
    }

    final packageTile = find.widgetWithText(ListTile, AppInfo.name);
    expect(packageTile, findsOneWidget);
    await tester.tap(packageTile);
    for (var i = 0; i < 5; i++) {
      await tester.pump(const Duration(milliseconds: 200));
    }

    expect(
      find.textContaining('BSD 3-Clause License', findRichText: true),
      findsWidgets,
    );
  });
}
