import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:music_are/core/config/app_info.dart';
import 'package:music_are/core/l10n/app_localizations.dart';
import 'package:music_are/features/settings/presentation/pages/about_page.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:plugin_platform_interface/plugin_platform_interface.dart';
import 'package:url_launcher_platform_interface/url_launcher_platform_interface.dart';

class FakeUrlLauncher extends Fake
    with MockPlatformInterfaceMixin
    implements UrlLauncherPlatform {
  final List<String> launched = [];

  @override
  Future<bool> launchUrl(String url, LaunchOptions options) async {
    launched.add(url);
    return true;
  }
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late FakeUrlLauncher launcher;

  setUp(() {
    PackageInfo.setMockInitialValues(
      appName: 'MusicAre',
      packageName: 'com.musicare.app',
      version: '1.2.3',
      buildNumber: '7',
      buildSignature: '',
    );
    launcher = FakeUrlLauncher();
    UrlLauncherPlatform.instance = launcher;
  });

  tearDown(() {
    UrlLauncherPlatform.instance = FakeUrlLauncher();
  });

  Future<void> pumpAbout(WidgetTester tester) async {
    await tester.pumpWidget(
      MaterialApp(
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: const AboutPage(),
      ),
    );
    await tester.pumpAndSettle();
  }

  testWidgets('shows the app identity, founder, repository and license', (
    tester,
  ) async {
    await pumpAbout(tester);

    expect(find.text('About MusicAre'), findsOneWidget);
    expect(find.text('MusicAre'), findsOneWidget);
    expect(find.text('v1.2.3 (7)'), findsOneWidget);
    expect(find.byType(Image), findsOneWidget);
    expect(find.text('Founder'), findsOneWidget);
    expect(find.text(AppInfo.founder), findsOneWidget);
    expect(find.text('Repository'), findsOneWidget);
    expect(find.text(AppInfo.repositoryLabel), findsOneWidget);
    expect(find.text('License'), findsOneWidget);
    expect(find.text('BSD-3-Clause'), findsOneWidget);
  });

  testWidgets('the founder and the repository open externally', (tester) async {
    await pumpAbout(tester);

    await tester.tap(find.text('Founder'));
    await tester.pumpAndSettle();
    expect(launcher.launched, [AppInfo.websiteUrl]);

    await tester.tap(find.text('Repository'));
    await tester.pumpAndSettle();
    expect(launcher.launched.last, AppInfo.repositoryUrl);
  });

  testWidgets('the license row opens the license page', (tester) async {
    await pumpAbout(tester);

    await tester.tap(find.text('License'));
    await tester.pumpAndSettle();

    expect(find.byType(LicensePage), findsOneWidget);
  });
}
