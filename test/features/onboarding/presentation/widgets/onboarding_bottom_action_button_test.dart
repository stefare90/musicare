import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:music_are/features/onboarding/presentation/widgets/onboarding_bottom_action_button.dart';

void main() {
  Widget buildTestableWidget({required VoidCallback onPressed}) {
    return MaterialApp(
      home: Scaffold(
        body: OnboardingBottomActionButton(
          label: 'Continue',
          icon: Icons.arrow_forward_rounded,
          onPressed: onPressed,
        ),
      ),
    );
  }

  group('OnboardingBottomActionButton Widget Tests', () {
    testWidgets('renders label, icon and triggers callback on press', (
      tester,
    ) async {
      bool pressed = false;

      await tester.pumpWidget(
        buildTestableWidget(onPressed: () => pressed = true),
      );
      await tester.pumpAndSettle();

      expect(find.text('Continue'), findsOneWidget);
      expect(find.byIcon(Icons.arrow_forward_rounded), findsOneWidget);

      await tester.tap(find.text('Continue'));
      expect(pressed, isTrue);
    });
  });
}
