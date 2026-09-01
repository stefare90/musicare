import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:music_are/features/onboarding/presentation/widgets/onboarding_step_scaffold.dart';

void main() {
  group('OnboardingStepScaffold Widget Tests', () {
    testWidgets(
      'renders header icon, title, subtitle, child and bottomAction',
      (tester) async {
        await tester.pumpWidget(
          const MaterialApp(
            home: Scaffold(
              body: OnboardingStepScaffold(
                title: 'Test Step Title',
                subtitle: 'Test Step Subtitle',
                icon: Icons.music_note_rounded,
                bottomAction: Text('Bottom Action Button Placeholder'),
                child: Text('Discovery Widget Content'),
              ),
            ),
          ),
        );

        expect(find.byIcon(Icons.music_note_rounded), findsOneWidget);
        expect(find.text('Test Step Title'), findsOneWidget);
        expect(find.text('Test Step Subtitle'), findsOneWidget);
        expect(find.text('Discovery Widget Content'), findsOneWidget);
        expect(find.text('Bottom Action Button Placeholder'), findsOneWidget);
      },
    );
  });
}
