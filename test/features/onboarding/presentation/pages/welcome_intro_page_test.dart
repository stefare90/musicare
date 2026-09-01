import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:music_are/core/l10n/app_localizations.dart';
import 'package:music_are/features/onboarding/presentation/pages/welcome_intro_page.dart';
import 'package:music_are/features/onboarding/presentation/widgets/onboarding_bottom_action_button.dart';

void main() {
  Widget buildTestableWidget({required VoidCallback onTap}) {
    return MaterialApp(
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      home: Scaffold(body: WelcomeIntroPage(onSelectMetadataTap: onTap)),
    );
  }

  group('WelcomeIntroPage Widget Tests', () {
    testWidgets('renders logo, title, slogan, hint, and button', (
      tester,
    ) async {
      bool tapped = false;

      await tester.pumpWidget(buildTestableWidget(onTap: () => tapped = true));
      await tester.pumpAndSettle();

      expect(find.byType(Image), findsOneWidget);
      expect(find.text('Welcome to MusicAre'), findsOneWidget);
      expect(
        find.text('Music are the plugins. We are the player.'),
        findsOneWidget,
      );
      expect(find.byType(OnboardingBottomActionButton), findsOneWidget);

      await tester.tap(find.text('Select Metadata Provider'));
      expect(tapped, isTrue);
    });
  });
}
