import 'package:flutter/material.dart';
import 'package:musicare_metadata_host_sdk/musicare_metadata_host_sdk.dart';
import 'package:music_are/core/widgets/media/track_list_tile.dart';

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

  const PaginatedTrackList({
    super.key,
    required this.tracks,
    this.activeTrackId,
    this.hasMore = false,
    this.isLoadingMore = false,
    this.onLoadMore,
    this.onTrackTap,
    this.onTrackOptionsTap,
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
            return const Center(
              child: Padding(
                padding: EdgeInsets.all(16.0),
                child: CircularProgressIndicator(),
              ),
            );
          }
          final track = tracks[index];
          return TrackListTile(
            track: track,
            isPlaying: track.id == activeTrackId,
            onTap: onTrackTap != null ? () => onTrackTap!(track) : null,
            onOptionsTap: onTrackOptionsTap != null
                ? () => onTrackOptionsTap!(track)
                : null,
          );
        },
      ),
    );
  }
}
