import 'package:flutter/material.dart';
import 'package:music_are/core/l10n/l10n_extension.dart';
import 'package:music_are/core/router/app_navigator.dart';

class AboutTile extends StatelessWidget {
  const AboutTile({super.key});

  @override
  Widget build(BuildContext context) {
    return ListTile(
      title: Text(context.l10n.settingsAboutRow),
      trailing: const Icon(Icons.chevron_right_rounded),
      onTap: () => AppNavigator.toAbout(context),
    );
  }
}
