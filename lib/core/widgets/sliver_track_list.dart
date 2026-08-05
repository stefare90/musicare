import 'package:flutter/material.dart';
import 'package:gyawun_metadata_sdk/metadata/models/track.dart';
import 'package:music_are/core/widgets/track_list_tile.dart';

class SliverTrackList extends StatelessWidget {
  final List<Track> tracks;
  final bool hasMore;
  final String? activeTrackId;
  final VoidCallback? onLoadMore;
  final void Function(Track track)? onTrackTap;
  final void Function(Track track)? onTrackOptionsTap;

  const SliverTrackList({
    super.key,
    required this.tracks,
    this.hasMore = false,
    this.activeTrackId,
    this.onLoadMore,
    this.onTrackTap,
    this.onTrackOptionsTap,
  });

  @override
  Widget build(BuildContext context) {
    if (tracks.isEmpty) {
      return const SliverToBoxAdapter(child: SizedBox.shrink());
    }
    return SliverList(
      delegate: SliverChildBuilderDelegate((context, index) {
        if (index == tracks.length) {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            onLoadMore?.call();
          });
          return const Padding(
            padding: EdgeInsets.symmetric(vertical: 16.0),
            child: Center(child: CircularProgressIndicator()),
          );
        }
        final track = tracks[index];
        final isPlaying = activeTrackId != null && activeTrackId == track.id;
        return TrackListTile(
          track: track,
          index: index + 1,
          isPlaying: isPlaying,
          onTap: onTrackTap != null ? () => onTrackTap!(track) : null,
          onOptionsTap: onTrackOptionsTap != null
              ? () => onTrackOptionsTap!(track)
              : null,
        );
      }, childCount: tracks.length + (hasMore ? 1 : 0)),
    );
  }
}
