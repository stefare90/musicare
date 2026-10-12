import 'package:flutter/material.dart';
import 'package:musicare_metadata_host_sdk/musicare_metadata_host_sdk.dart';
import 'package:music_are/core/theme/theme_extension.dart';
import 'package:music_are/core/widgets/media/track_list_tile.dart';
import 'package:music_are/core/widgets/skeletons/skeleton_track_list.dart';

/// Source-agnostic list like [PaginatedMediaGrid]: the caller provides the
/// tracks and reacts to [onLoadMore].
class PaginatedTrackList extends StatelessWidget {
  final List<Track> tracks;
  final String? activeTrackId;
  final bool hasMore;
  final bool isLoadingMore;
  final VoidCallback? onLoadMore;
  final void Function(Track track)? onTrackTap;
  final void Function(Track track)? onTrackOptionsTap;
  final Future<bool> Function(Track track)? confirmTrackDismiss;
  final void Function(Track track)? onTrackDismissed;

  const PaginatedTrackList({
    super.key,
    required this.tracks,
    this.activeTrackId,
    this.hasMore = false,
    this.isLoadingMore = false,
    this.onLoadMore,
    this.onTrackTap,
    this.onTrackOptionsTap,
    this.confirmTrackDismiss,
    this.onTrackDismissed,
  });

  @override
  Widget build(BuildContext context) {
    return NotificationListener<ScrollNotification>(
      onNotification: (scrollInfo) {
        if (hasMore && !isLoadingMore && scrollInfo.metrics.extentAfter < 200) {
          onLoadMore?.call();
        }
        return false;
      },
      child: ListView.builder(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.symmetric(vertical: 8.0),
        itemCount: tracks.length + (isLoadingMore ? 1 : 0),
        itemBuilder: (context, index) {
          if (index >= tracks.length) {
            return const SkeletonTrackList(count: 1);
          }
          final track = tracks[index];
          final tile = TrackListTile(
            track: track,
            isPlaying: track.id == activeTrackId,
            onTap: onTrackTap != null ? () => onTrackTap!(track) : null,
            onOptionsTap: onTrackOptionsTap != null
                ? () => onTrackOptionsTap!(track)
                : null,
          );
          if (onTrackDismissed == null) return tile;
          return Dismissible(
            key: ValueKey('track_dismiss_${index}_${track.id}'),
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
            confirmDismiss: confirmTrackDismiss != null
                ? (_) => confirmTrackDismiss!(track)
                : null,
            onDismissed: (_) => onTrackDismissed!(track),
            child: tile,
          );
        },
      ),
    );
  }
}
