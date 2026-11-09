import 'package:flutter/material.dart';
import 'package:music_are/core/l10n/l10n_extension.dart';
import 'package:music_are/core/theme/theme_extension.dart';
import 'package:music_are/core/widgets/dialogs.dart';
import 'package:url_launcher/url_launcher.dart';

class PluginRepositoryLink extends StatelessWidget {
  final String repository;

  const PluginRepositoryLink({super.key, required this.repository});

  Future<void> _open(BuildContext context) async {
    var opened = false;
    try {
      opened = await launchUrl(
        Uri.parse(repository),
        mode: LaunchMode.externalApplication,
      );
    } on Exception {
      opened = false;
    }
    if (!opened && context.mounted) {
      Dialogs.showMessageSnackBar(
        context,
        message: context.l10n.linkOpenFailed,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: Alignment.centerLeft,
      child: TextButton.icon(
        onPressed: () => _open(context),
        icon: const Icon(Icons.open_in_new_rounded, size: 14.0),
        label: Text(context.l10n.settingsAboutRepository),
        style: TextButton.styleFrom(
          padding: EdgeInsets.zero,
          minimumSize: const Size(0.0, 28.0),
          tapTargetSize: MaterialTapTargetSize.shrinkWrap,
          visualDensity: VisualDensity.compact,
          textStyle: context.textTheme.bodySmall,
        ),
      ),
    );
  }
}
