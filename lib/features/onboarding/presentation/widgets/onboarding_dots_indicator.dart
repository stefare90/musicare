import 'package:flutter/material.dart';
import 'package:music_are/core/theme/theme_extension.dart';

class OnboardingDotsIndicator extends StatelessWidget {
  final int currentPage;
  final int totalDots;

  const OnboardingDotsIndicator({
    super.key,
    required this.currentPage,
    this.totalDots = 3,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: 8.0, bottom: 20.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: List.generate(totalDots, (index) {
          final isSelected = currentPage == index;
          return AnimatedContainer(
            duration: const Duration(milliseconds: 250),
            curve: Curves.easeInOut,
            margin: const EdgeInsets.symmetric(horizontal: 4.0),
            height: 8,
            width: isSelected ? 20 : 10,
            decoration: BoxDecoration(
              color: isSelected
                  ? context.colorScheme.primary
                  : context.colorScheme.primary.withValues(alpha: 0.2),
              borderRadius: BorderRadius.circular(4),
            ),
          );
        }),
      ),
    );
  }
}
