import 'package:flutter/material.dart';
import 'package:music_are/core/theme/theme_extension.dart';

class SettingsSectionHeader extends StatelessWidget {
  final String label;

  const SettingsSectionHeader({super.key, required this.label});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16.0, 16.0, 16.0, 4.0),
      child: Text(
        label,
        style: context.textTheme.labelLarge?.copyWith(
          color: context.colorScheme.primary,
        ),
      ),
    );
  }
}
