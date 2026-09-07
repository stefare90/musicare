import 'package:flutter/material.dart';
import 'package:gyawun_metadata_sdk/metadata/models/image.dart' as sdk;
import 'package:gyawun_metadata_sdk/metadata/models/track.dart';
import 'package:music_are/core/l10n/l10n_extension.dart';
import 'package:music_are/core/models/media_type.dart';
import 'package:music_are/core/theme/theme_extension.dart';
import 'package:music_are/core/widgets/media/media_cover_image.dart';

class TrackListTile extends StatelessWidget {
  final Track track;
  final int? index;
  final bool isPlaying;
  final VoidCallback? onTap;
  final VoidCallback? onOptionsTap;

  const TrackListTile({
    super.key,
    required this.track,
    this.index,
    this.isPlaying = false,
    this.onTap,
    this.onOptionsTap,
  });

  @override
  Widget build(BuildContext context) {
    final artistNames = track.artists.map((a) => a.name).join(', ');
    final coverImages = track.album.images;

    return Material(
      color: isPlaying
          ? context.colorScheme.primary.withValues(alpha: 0.08)
          : Colors.transparent,
      child: ListTile(
        onTap: onTap,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 16.0,
          vertical: 2.0,
        ),
        leading: _buildLeading(context, coverImages),
        title: Text(
          track.name,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: context.textTheme.titleMedium?.copyWith(
            fontWeight: isPlaying ? FontWeight.bold : null,
            color: isPlaying ? context.colorScheme.primary : null,
          ),
        ),
        subtitle: artistNames.isNotEmpty
            ? Text(
                artistNames,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: context.textTheme.bodyMedium?.copyWith(
                  color: context.colorScheme.onSurfaceVariant,
                ),
              )
            : null,
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (track.durationMs > 0)
              Text(
                _formatDuration(track.durationMs),
                style: context.textTheme.labelSmall?.copyWith(
                  color: context.colorScheme.onSurfaceVariant,
                ),
              ),
            IconButton(
              icon: const Icon(Icons.more_vert),
              onPressed: onOptionsTap,
              tooltip: context.l10n.tooltipOptions,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLeading(BuildContext context, List<sdk.Image>? coverImages) {
    if (index != null) {
      return SizedBox(
        width: 32,
        height: 40,
        child: Center(
          child: Text(
            '$index',
            style: context.textTheme.bodyMedium?.copyWith(
              color: isPlaying
                  ? context.colorScheme.primary
                  : context.colorScheme.onSurfaceVariant,
              fontWeight: isPlaying ? FontWeight.bold : null,
            ),
          ),
        ),
      );
    }
    return MediaCoverImage(
      images: coverImages,
      mediaType: MediaType.track,
      width: 44,
      height: 44,
      borderRadius: BorderRadius.circular(8.0),
    );
  }

  String _formatDuration(int durationMs) {
    final duration = Duration(milliseconds: durationMs);
    final minutes = duration.inMinutes;
    final seconds = duration.inSeconds.remainder(60).toString().padLeft(2, '0');
    return '$minutes:$seconds';
  }
}
