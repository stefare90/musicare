import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:music_are/features/onboarding/presentation/widgets/onboarding_dots_indicator.dart';

void main() {
  group('OnboardingDotsIndicator Widget Tests', () {
    testWidgets('renders correct number of animated dots', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: OnboardingDotsIndicator(currentPage: 1, totalDots: 3),
          ),
        ),
      );

      // Finds 3 animated container dots
      expect(find.byType(AnimatedContainer), findsNWidgets(3));

      // Second dot (index 1) is active with expanded width
      final secondDot = tester.widget<AnimatedContainer>(
        find.byType(AnimatedContainer).at(1),
      );
      expect(secondDot.constraints?.maxWidth, equals(20.0));
    });
  });
}
