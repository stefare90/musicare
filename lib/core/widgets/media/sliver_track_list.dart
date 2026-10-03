import 'package:flutter/material.dart';
import 'package:musicare_metadata_host_sdk/musicare_metadata_host_sdk.dart';
import 'package:music_are/core/l10n/l10n_extension.dart';
import 'package:music_are/core/models/media_type.dart';
import 'package:music_are/core/theme/theme_extension.dart';
import 'package:music_are/core/widgets/error_tile.dart';
import 'package:music_are/core/widgets/media/track_list_tile.dart';
import 'package:music_are/core/widgets/skeletons/skeleton_track_list.dart';
import 'package:music_are/core/widgets/skeletons/sliver_skeleton_track_list.dart';

class SliverTrackList extends StatelessWidget {
  final String? title;
  final List<Track> tracks;
  final MediaType listType;
  final bool isLoading;
  final Object? error;
  final Object? loadMoreError;
  final VoidCallback? onRetry;
  final bool hasMore;
  final String? activeTrackId;
  final VoidCallback? onLoadMore;
  final void Function(Track track)? onTrackTap;
  final void Function(Track track)? onTrackOptionsTap;
  final Future<bool> Function(Track track)? confirmTrackDismiss;
  final void Function(Track track)? onTrackDismissed;

  const SliverTrackList({
    super.key,
    this.title,
    this.tracks = const [],
    required this.listType,
    this.isLoading = false,
    this.error,
    this.loadMoreError,
    this.onRetry,
    this.hasMore = false,
    this.activeTrackId,
    this.onLoadMore,
    this.onTrackTap,
    this.onTrackOptionsTap,
    this.confirmTrackDismiss,
    this.onTrackDismissed,
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
          onRetry: onRetry,
        ),
      );
    }
    if (isLoading) {
      return SliverSkeletonTrackList(
        showTitle: title != null && title!.isNotEmpty,
        count: 5,
      );
    }
    if (tracks.isEmpty) {
      return const SliverToBoxAdapter(child: SizedBox(height: 0));
    }
    final sliverlist = SliverList(
      delegate: SliverChildBuilderDelegate((context, index) {
        if (index == tracks.length) {
          if (loadMoreError != null) {
            return ErrorTile(
              title: context.l10n.moreTracks,
              error: loadMoreError!,
              onRetry: () => onLoadMore?.call(),
            );
          }
          WidgetsBinding.instance.addPostFrameCallback((_) {
            onLoadMore?.call();
          });
          return const SkeletonTrackList(count: 1, showTitle: false);
        }
        final track = tracks[index];
        final isPlaying = activeTrackId != null && activeTrackId == track.id;
        final tile = TrackListTile(
          track: track,
          index: _shouldShowTrackNumbers ? index + 1 : null,
          isPlaying: isPlaying,
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
              child: Text(title!, style: context.textTheme.titleLarge),
            ),
          ),
          sliverlist,
        ],
      );
    }

    return sliverlist;
  }
}
