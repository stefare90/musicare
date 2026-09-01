import 'package:flutter/material.dart';

class OnboardingBottomActionButton extends StatelessWidget {
  final String label;
  final IconData icon;
  final VoidCallback onPressed;

  const OnboardingBottomActionButton({
    super.key,
    required this.label,
    required this.icon,
    required this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20.0, 6.0, 20.0, 16.0),
      child: SizedBox(
        width: double.infinity,
        child: ElevatedButton.icon(
          onPressed: onPressed,
          iconAlignment: IconAlignment.end,
          icon: Icon(icon),
          label: Text(label),
        ),
      ),
    );
  }
}
