import 'package:flutter/material.dart';
import 'package:music_are/core/theme/theme_extension.dart';

class SettingsInfoTile extends StatelessWidget {
  final String label;
  final String value;

  const SettingsInfoTile({super.key, required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return ListTile(
      dense: true,
      title: Text(label),
      trailing: Text(
        value,
        style: context.textTheme.bodyMedium?.copyWith(
          color: context.colorScheme.onSurfaceVariant,
        ),
      ),
    );
  }
}
