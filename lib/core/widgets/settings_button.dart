import 'package:flutter/material.dart';
import 'package:music_are/core/l10n/l10n_extension.dart';
import 'package:music_are/core/router/app_navigator.dart';

/// Opens the settings hub. This is the only configuration entry point in the
/// root screens; plugin accounts and versions live inside it.
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
