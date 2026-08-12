import 'package:flutter/material.dart';
import 'package:gyawun_metadata_sdk/metadata/models/track.dart';
import 'package:music_are/core/l10n/l10n_extension.dart';
import 'package:music_are/core/models/media_type.dart';
import 'package:music_are/core/widgets/error_tile.dart';
import 'package:music_are/core/widgets/media/track_list_tile.dart';
import 'package:music_are/core/widgets/skeletons/sliver_skeleton_track_list.dart';

class SliverTrackList extends StatelessWidget {
  final String? title;
  final List<Track> tracks;
  final MediaType listType;
  final bool isLoading;
  final Object? error;
  final VoidCallback? onRetry;
  final bool hasMore;
  final String? activeTrackId;
  final VoidCallback? onLoadMore;
  final void Function(Track track)? onTrackTap;
  final void Function(Track track)? onTrackOptionsTap;

  const SliverTrackList({
    super.key,
    this.title,
    this.tracks = const [],
    required this.listType,
    this.isLoading = false,
    this.error,
    this.onRetry,
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
    if (error != null) {
      return SliverToBoxAdapter(
        child: ErrorTile(
          title: title ?? context.l10n.error,
          error: error!,
          onRetry: onRetry!,
        ),
      );
    }
    if (isLoading) {
      return SliverSkeletonTrackList(showTitle: title != null, count: 5);
    }
    if (tracks.isEmpty) {
      return const SliverToBoxAdapter(child: SizedBox.shrink());
    }
    final silverList = SliverList(
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
    if (title != null && title!.isNotEmpty) {
      return SliverMainAxisGroup(
        slivers: [
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: 16.0,
                vertical: 8.0,
              ),
              child: Text(
                title!,
                style: Theme.of(context).textTheme.titleLarge,
              ),
            ),
          ),
          silverList,
        ],
      );
    }

    return silverList;
  }
}
