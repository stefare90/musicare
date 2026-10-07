import 'package:flutter/material.dart';
import 'package:music_are/core/l10n/l10n_extension.dart';
import 'package:music_are/core/router/app_navigator.dart';

class SettingsButton extends StatelessWidget {
  const SettingsButton({super.key});

  @override
  Widget build(BuildContext context) {
    return IconButton(
      tooltip: context.l10n.settingsTitle,
      icon: const Icon(Icons.settings_outlined),
      onPressed: () => AppNavigator.toSettings(context),
    );
  }
}
