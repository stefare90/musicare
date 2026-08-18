import 'package:flutter/material.dart';
import 'package:gyawun_metadata_sdk/metadata/models/track.dart';
import 'package:music_are/core/theme/theme_extension.dart';
import 'package:music_are/core/widgets/error_tile.dart';
import 'package:music_are/core/widgets/media/media_card_error.dart';
import 'package:music_are/core/widgets/media/track_list_tile.dart';
import 'package:music_are/core/widgets/skeletons/skeleton_track_matrix.dart';
import 'package:music_are/core/widgets/skeletons/skeleton_track_matrix_column.dart';

class TrackMatrix extends StatelessWidget {
  final String title;
  final String? description;
  final List<Track> tracks;
  final double matrixHeight;
  final int rowsCount;
  final bool isLoading;
  final bool isLoadingMore;
  final bool hasMore;
  final Object? error;
  final Object? loadMoreError;
  final VoidCallback? onRetry;
  final VoidCallback? onLoadMore;
  final String? activeTrackId;
  final void Function(Track track)? onTrackTap;
  final void Function(Track track)? onTrackOptionsTap;

  const TrackMatrix({
    super.key,
    required this.title,
    this.description,
    this.tracks = const [],
    this.matrixHeight = 200.0,
    this.rowsCount = 3,
    this.isLoading = false,
    this.isLoadingMore = false,
    this.hasMore = false,
    this.error,
    this.loadMoreError,
    this.onRetry,
    this.onLoadMore,
    this.activeTrackId,
    this.onTrackTap,
    this.onTrackOptionsTap,
  });

  List<List<Track>> _chunkTracks(List<Track> list, int size) {
    final List<List<Track>> chunks = [];
    for (var i = 0; i < list.length; i += size) {
      chunks.add(
        list.sublist(i, i + size > list.length ? list.length : i + size),
      );
    }
    return chunks;
  }

  @override
  Widget build(BuildContext context) {
    if (error != null && tracks.isEmpty) {
      return ErrorTile(title: title, error: error!, onRetry: onRetry ?? () {});
    }
    final screenWidth = MediaQuery.of(context).size.width;
    final columnWidth = screenWidth > 500 ? 360.0 : (screenWidth * 0.88);
    if (isLoading && tracks.isEmpty) {
      return SkeletonTrackMatrix(
        rowsCount: rowsCount,
        totalHeight: matrixHeight,
        columnWidth: columnWidth,
      );
    }
    if (tracks.isEmpty) return const SizedBox.shrink();
    final chunks = _chunkTracks(tracks, rowsCount);
    final rowSlotHeight = matrixHeight / rowsCount;
    final showTrailing = hasMore || isLoadingMore || loadMoreError != null;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(title, style: context.textTheme.titleLarge),
              if (description != null && description!.isNotEmpty) ...[
                const SizedBox(height: 4),
                Text(description!, style: context.textTheme.bodyMedium),
              ],
            ],
          ),
        ),
        SizedBox(
          height: matrixHeight,
          child: NotificationListener<ScrollNotification>(
            onNotification: (ScrollNotification scrollInfo) {
              if (hasMore &&
                  !isLoadingMore &&
                  loadMoreError == null &&
                  scrollInfo.metrics.extentAfter < 200) {
                onLoadMore?.call();
              }
              return false;
            },
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 12.0),
              itemCount: chunks.length + (showTrailing ? 1 : 0),
              itemBuilder: (context, columnIndex) {
                if (columnIndex < chunks.length) {
                  final columnTracks = chunks[columnIndex];

                  return Container(
                    width: columnWidth,
                    margin: const EdgeInsets.symmetric(horizontal: 4.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: List.generate(columnTracks.length, (rowIndex) {
                        final track = columnTracks[rowIndex];
                        final isPlaying =
                            activeTrackId != null && activeTrackId == track.id;

                        return SizedBox(
                          height: rowSlotHeight,
                          child: Center(
                            child: TrackListTile(
                              track: track,
                              isPlaying: isPlaying,
                              onTap: onTrackTap != null
                                  ? () => onTrackTap!(track)
                                  : null,
                              onOptionsTap: onTrackOptionsTap != null
                                  ? () => onTrackOptionsTap!(track)
                                  : null,
                            ),
                          ),
                        );
                      }),
                    ),
                  );
                }

                if (loadMoreError != null) {
                  return MediaCardError(
                    title: title,
                    error: loadMoreError!,
                    onRetry: onLoadMore,
                  );
                }

                return SkeletonTrackMatrixColumn(
                  rowsCount: rowsCount,
                  columnWidth: columnWidth,
                  totalHeight: matrixHeight,
                );
              },
            ),
          ),
        ),
        const SizedBox(height: 16),
      ],
    );
  }
}
