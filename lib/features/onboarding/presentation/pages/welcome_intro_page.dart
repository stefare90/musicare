import 'package:flutter/material.dart';
import 'package:music_are/core/l10n/l10n_extension.dart';
import 'package:music_are/core/theme/theme_extension.dart';
import 'package:music_are/features/onboarding/presentation/widgets/onboarding_bottom_action_button.dart';

class WelcomeIntroPage extends StatelessWidget {
  final VoidCallback onSelectMetadataTap;

  const WelcomeIntroPage({super.key, required this.onSelectMetadataTap});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Expanded(
          child: Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(
                horizontal: 24.0,
                vertical: 12.0,
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  ClipRRect(
                    borderRadius: BorderRadius.circular(38),
                    child: Image.asset(
                      'assets/images/app_icon.png',
                      height: 200,
                      width: 200,
                      fit: BoxFit.cover,
                    ),
                  ),
                  const SizedBox(height: 10),
                  Text(
                    context.l10n.welcomeTitle,
                    textAlign: TextAlign.center,
                    style: context.textTheme.headlineMedium,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    context.l10n.appSlogan,
                    textAlign: TextAlign.center,
                    style: context.textTheme.titleMedium?.copyWith(
                      color: context.colorScheme.primary,
                    ),
                  ),
                  const SizedBox(height: 14),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 12.0),
                    child: Text(
                      context.l10n.welcomeSetupHint,
                      textAlign: TextAlign.center,
                      style: context.textTheme.bodyMedium,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
        OnboardingBottomActionButton(
          label: context.l10n.selectMetadataProvider,
          icon: Icons.arrow_forward_rounded,
          onPressed: onSelectMetadataTap,
        ),
      ],
    );
  }
}
