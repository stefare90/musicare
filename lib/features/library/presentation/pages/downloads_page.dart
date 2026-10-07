import 'package:flutter/material.dart';
import 'package:music_are/core/l10n/l10n_extension.dart';
import 'package:music_are/core/widgets/info_card.dart';
import 'package:music_are/core/widgets/scrollable_centered.dart';

class DownloadsPage extends StatelessWidget {
  const DownloadsPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(context.l10n.downloads)),
      body: ScrollableCentered(
        child: InfoCard(
          icon: Icons.download_rounded,
          title: context.l10n.downloadsEmptyTitle,
          message: context.l10n.downloadsEmptyMessage,
        ),
      ),
    );
  }
}
