import 'package:flutter/material.dart';
import 'package:musicare_metadata_host_sdk/musicare_metadata_host_sdk.dart';
import 'package:music_are/core/models/media_type.dart';
import 'package:music_are/core/theme/theme_extension.dart';
import 'package:music_are/core/widgets/media/media_cover_image.dart';

class QueueTrackTile extends StatelessWidget {
  final Track track;
  final int index;
  final bool isPlaying;
  final VoidCallback onTap;
  final VoidCallback onDismissed;

  const QueueTrackTile({
    super.key,
    required this.track,
    required this.index,
    required this.isPlaying,
    required this.onTap,
    required this.onDismissed,
  });

  @override
  Widget build(BuildContext context) {
    final artistNames = track.artists.map((a) => a.name).join(', ');

    final tile = Material(
      key: ValueKey('queue_tile_${track.id}_$index'),
      color: isPlaying
          ? context.colorScheme.primary.withValues(alpha: 0.12)
          : Colors.transparent,
      child: ListTile(
        onTap: onTap,
        leading: MediaCoverImage(
          images: track.album.images,
          mediaType: MediaType.track,
          width: 44,
          height: 44,
          borderRadius: BorderRadius.circular(6),
        ),
        title: Text(
          track.name,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: context.textTheme.titleSmall?.copyWith(
            color: isPlaying ? context.colorScheme.primary : null,
          ),
        ),
        subtitle: artistNames.isNotEmpty
            ? Text(
                artistNames,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: context.textTheme.labelSmall,
              )
            : null,
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (isPlaying)
              Padding(
                padding: const EdgeInsets.only(right: 8.0),
                child: Icon(
                  Icons.equalizer_rounded,
                  size: 20,
                  color: context.colorScheme.primary,
                ),
              ),
            ReorderableDragStartListener(
              index: index,
              child: Icon(
                Icons.drag_handle_rounded,
                color: context.colorScheme.onSurfaceVariant.withValues(
                  alpha: 0.6,
                ),
              ),
            ),
          ],
        ),
      ),
    );
    if (isPlaying) {
      return tile;
    }
    return Dismissible(
      key: ValueKey('queue_dismiss_${track.id}_$index'),
      direction: DismissDirection.endToStart,
      background: Container(
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.symmetric(horizontal: 20.0),
        color: context.colorScheme.error,
        child: Icon(
          Icons.delete_outline_rounded,
          color: context.colorScheme.onError,
        ),
      ),
      onDismissed: (_) => onDismissed(),
      child: tile,
    );
  }
}
