import 'package:flutter/material.dart';
import 'package:gyawun_metadata_sdk/metadata/models/track.dart';
import 'package:music_are/core/models/media_type.dart';
import 'package:music_are/core/widgets/media/track_list_tile.dart';

class SliverTrackList extends StatelessWidget {
  final List<Track> tracks;
  final MediaType listType;
  final bool hasMore;
  final String? activeTrackId;
  final VoidCallback? onLoadMore;
  final void Function(Track track)? onTrackTap;
  final void Function(Track track)? onTrackOptionsTap;

  const SliverTrackList({
    super.key,
    required this.tracks,
    required this.listType,
    this.hasMore = false,
    this.activeTrackId,
    this.onLoadMore,
    this.onTrackTap,
    this.onTrackOptionsTap,
  });

  bool get _shouldShowTrackNumbers {
    return listType == MediaType.album || listType == MediaType.single;
  }

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
          index: _shouldShowTrackNumbers ? index + 1 : null,
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
