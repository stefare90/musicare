import 'package:flutter/material.dart';
import 'package:musicare_metadata_host_sdk/musicare_metadata_host_sdk.dart';
import 'package:music_are/core/l10n/l10n_extension.dart';
import 'package:music_are/core/models/media_type.dart';
import 'package:music_are/core/widgets/dialogs.dart';
import 'package:music_are/core/widgets/media/media_cover_image.dart';
import 'package:music_are/features/library/presentation/widgets/favorite_button.dart';
import 'package:music_are/features/player/presentation/cubit/player_state.dart';
import 'package:music_are/features/player/presentation/widgets/player_playback_controls.dart';
import 'package:music_are/features/player/presentation/widgets/player_scrubber.dart';
import 'package:music_are/features/player/presentation/widgets/player_secondary_actions.dart';
import 'package:music_are/features/player/presentation/widgets/player_track_info.dart';

class FullPlayerLandscapeView extends StatelessWidget {
  final Track track;
  final PlayerState state;
  final VoidCallback? onCollapse;

  const FullPlayerLandscapeView({
    super.key,
    required this.track,
    required this.state,
    this.onCollapse,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(28.0, 4.0, 28.0, 16.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          // Left: Cover Art
          Expanded(
            flex: 5,
            child: Center(
              child: Padding(
                padding: const EdgeInsets.all(12.0),
                child: AspectRatio(
                  aspectRatio: 1.0,
                  child: Container(
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(20),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.35),
                          blurRadius: 24,
                          offset: const Offset(0, 10),
                        ),
                      ],
                    ),
                    child: MediaCoverImage(
                      images: track.album.images,
                      mediaType: MediaType.track,
                      borderRadius: BorderRadius.circular(20),
                    ),
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(width: 28),

          // Right: Track Info, Controls & Utilities
          Expanded(
            flex: 6,
            child: Column(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: PlayerTrackInfo(
                        track: track,
                        onCollapse: onCollapse,
                        isCentered: false,
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.download_rounded),
                      tooltip: 'Download',
                      onPressed: () => Dialogs.showSnackBar(
                        context,
                        message: context.l10n.downloadComingSoon,
                      ),
                    ),
                    FavoriteButton(track: track),
                  ],
                ),
                PlayerScrubber(state: state),
                PlayerPlaybackControls(state: state),
                PlayerSecondaryActions(track: track),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
