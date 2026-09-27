import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:music_are/core/l10n/app_localizations.dart';
import 'package:music_are/core/widgets/sign_in_card.dart';

void main() {
  Widget buildTestableWidget(Widget child) {
    return MaterialApp(
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      home: Scaffold(body: Center(child: child)),
    );
  }

  testWidgets('renders the default copy with a fixed Sign in action', (
    tester,
  ) async {
    var signInTaps = 0;

    await tester.pumpWidget(
      buildTestableWidget(SignInCard(onSignIn: () => signInTaps++)),
    );
    await tester.pumpAndSettle();

    expect(find.text('Sign in to continue'), findsOneWidget);
    expect(find.text('This content belongs to your account.'), findsOneWidget);

    await tester.tap(find.text('Sign in'));
    await tester.pumpAndSettle();
    expect(signInTaps, 1);
  });

  testWidgets('renders the provided copy', (tester) async {
    await tester.pumpWidget(
      buildTestableWidget(
        const SignInCard(title: 'Your library', message: 'Sign in to continue.'),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Your library'), findsOneWidget);
    expect(find.text('Sign in to continue.'), findsOneWidget);
  });
}
