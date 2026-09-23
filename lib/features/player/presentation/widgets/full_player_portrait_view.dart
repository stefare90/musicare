import 'package:flutter/material.dart';
import 'package:musicare_metadata_host_sdk/musicare_metadata_host_sdk.dart';
import 'package:music_are/core/l10n/l10n_extension.dart';
import 'package:music_are/core/models/media_type.dart';
import 'package:music_are/core/widgets/dialogs.dart';
import 'package:music_are/core/widgets/media/media_cover_image.dart';
import 'package:music_are/features/player/presentation/cubit/player_state.dart';
import 'package:music_are/features/player/presentation/widgets/player_playback_controls.dart';
import 'package:music_are/features/player/presentation/widgets/player_scrubber.dart';
import 'package:music_are/features/player/presentation/widgets/player_secondary_actions.dart';
import 'package:music_are/features/player/presentation/widgets/player_track_info.dart';

class FullPlayerPortraitView extends StatelessWidget {
  final Track track;
  final PlayerState state;
  final VoidCallback? onCollapse;

  const FullPlayerPortraitView({
    super.key,
    required this.track,
    required this.state,
    this.onCollapse,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24.0),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          // 1. Cover Art
          Expanded(
            child: Center(
              child: Padding(
                padding: const EdgeInsets.only(top: 14.0, bottom: 8.0),
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
          const SizedBox(height: 16),

          // 2. Track Title & Artists
          PlayerTrackInfo(
            track: track,
            onCollapse: onCollapse,
            isCentered: true,
          ),
          const SizedBox(height: 16),

          // 3. Action Row: Download & Favorite
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              IconButton(
                icon: const Icon(Icons.download_rounded),
                tooltip: 'Download',
                onPressed: () => Dialogs.showSnackBar(
                  context,
                  message: context.l10n.downloadComingSoon,
                ),
              ),
              IconButton(
                icon: const Icon(Icons.favorite_border_rounded),
                tooltip: context.l10n.tooltipFavorite,
                onPressed: () => Dialogs.showSnackBar(
                  context,
                  message: context.l10n.favoritesComingSoon,
                ),
              ),
            ],
          ),
          const SizedBox(height: 18),

          // 4. Scrubber Slider
          PlayerScrubber(state: state),
          const SizedBox(height: 20),

          // 5. Playback Controls
          PlayerPlaybackControls(state: state),
          const SizedBox(height: 24),

          // 6. Secondary Utilities
          Padding(
            padding: const EdgeInsets.only(bottom: 28.0),
            child: PlayerSecondaryActions(track: track),
          ),
        ],
      ),
    );
  }
}
