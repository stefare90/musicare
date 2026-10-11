import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:musicare_metadata_host_sdk/musicare_metadata_host_sdk.dart';
import 'package:music_are/core/router/app_navigator.dart';
import 'package:music_are/features/library/presentation/utils/track_actions.dart';
import 'package:music_are/core/widgets/media/paginated_media_grid.dart';
import 'package:music_are/core/widgets/media/track_list_tile.dart';
import 'package:music_are/features/player/presentation/cubit/player_cubit.dart';
import 'package:music_are/features/search/presentation/cubit/search_cubit.dart';
import 'package:music_are/features/search/presentation/cubit/search_state.dart';

class CategoryResultsView extends StatelessWidget {
  final SearchState state;
  final SearchCategory category;

  const CategoryResultsView({
    super.key,
    required this.state,
    required this.category,
  });

  @override
  Widget build(BuildContext context) {
    final activeTrackId = context.select<PlayerCubit, String?>(
      (c) => c.state.currentTrack?.id,
    );

    switch (category) {
      case SearchCategory.tracks:
        final items = state.trackResults?.items ?? [];
        return NotificationListener<ScrollNotification>(
          onNotification: (scrollInfo) {
            if (state.hasMore &&
                !state.isLoadingMore &&
                state.loadMoreError == null &&
                scrollInfo.metrics.extentAfter < 200) {
              context.read<SearchCubit>().loadMore();
            }
            return false;
          },
          child: ListView.builder(
            padding: const EdgeInsets.symmetric(vertical: 8.0),
            itemCount: items.length + (state.isLoadingMore ? 1 : 0),
            itemBuilder: (context, index) {
              if (index >= items.length) {
                return const Center(
                  child: Padding(
                    padding: EdgeInsets.all(16.0),
                    child: CircularProgressIndicator(),
                  ),
                );
              }
              final track = items[index];
              return TrackListTile(
                track: track,
                isPlaying: track.id == activeTrackId,
                onTap: () {
                  context.read<PlayerCubit>().playTrack(track);
                },
                onOptionsTap: () {
                  TrackActions.showOptions(context, track);
                },
              );
            },
          ),
        );

      case SearchCategory.albums:
        return PaginatedMediaGrid(
          items: state.albumResults?.items ?? [],
          hasMore: state.hasMore,
          isLoadingMore: state.isLoadingMore,
          onLoadMore: () => context.read<SearchCubit>().loadMore(),
          onItemTap: (item) => AppNavigator.toMediaDetail(context, item),
        );

      case SearchCategory.artists:
        return PaginatedMediaGrid(
          items: state.artistResults?.items ?? [],
          hasMore: state.hasMore,
          isLoadingMore: state.isLoadingMore,
          onLoadMore: () => context.read<SearchCubit>().loadMore(),
          onItemTap: (item) => AppNavigator.toMediaDetail(context, item),
        );

      case SearchCategory.playlists:
        return PaginatedMediaGrid(
          items: state.playlistResults?.items ?? [],
          hasMore: state.hasMore,
          isLoadingMore: state.isLoadingMore,
          onLoadMore: () => context.read<SearchCubit>().loadMore(),
          onItemTap: (item) => AppNavigator.toMediaDetail(context, item),
        );
    }
  }
}
