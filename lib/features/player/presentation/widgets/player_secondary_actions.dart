import 'package:flutter/material.dart';
import 'package:musicare_metadata_host_sdk/musicare_metadata_host_sdk.dart';
import 'package:music_are/core/l10n/l10n_extension.dart';
import 'package:music_are/core/widgets/bottom_sheets/audio_source_bottom_sheet.dart';
import 'package:music_are/core/widgets/bottom_sheets/queue_bottom_sheet.dart';
import 'package:music_are/core/widgets/dialogs.dart';

class PlayerSecondaryActions extends StatelessWidget {
  final Track track;

  const PlayerSecondaryActions({super.key, required this.track});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: [
        IconButton(
          icon: const Icon(Icons.graphic_eq_rounded),
          tooltip: context.l10n.audioStreamCandidates,
          onPressed: () => AudioSourceBottomSheet.show(context, track),
        ),
        IconButton(
          icon: const Icon(Icons.lyrics_outlined),
          tooltip: 'Lyrics',
          onPressed: () =>
              Dialogs.showSnackBar(context, message: context.l10n.lyricsComingSoon),
        ),
        IconButton(
          icon: const Icon(Icons.queue_music_rounded),
          tooltip: context.l10n.playbackQueue,
          onPressed: () => QueueBottomSheet.show(context),
        ),
      ],
    );
  }
}
