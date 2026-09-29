import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:musicare_metadata_host_sdk/musicare_metadata_host_sdk.dart';
import 'package:music_are/core/widgets/media/media_card_metrics.dart';
import 'package:music_are/core/widgets/skeletons/skeleton_media_grid.dart';
import 'package:music_are/core/widgets/skeletons/skeleton_search_all.dart';
import 'package:music_are/core/widgets/skeletons/skeleton_track_list.dart';
import 'package:music_are/features/search/presentation/cubit/search_cubit.dart';

class SearchLoadingView extends StatelessWidget {
  const SearchLoadingView({super.key});

  @override
  Widget build(BuildContext context) {
    final category = context.select<SearchCubit, SearchCategory?>(
      (c) => c.state.selectedChip,
    );

    switch (category) {
      case null:
        return const SkeletonSearchAll();
      case SearchCategory.tracks:
        return ListView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.symmetric(vertical: 8.0),
          children: const [SkeletonTrackList(count: 10)],
        );
      case SearchCategory.albums:
      case SearchCategory.artists:
      case SearchCategory.playlists:
        return LayoutBuilder(
          builder: (context, constraints) {
            final columns = MediaCardMetrics.gridColumns(constraints.maxWidth);
            return SkeletonMediaGrid(
              itemCount: MediaCardMetrics.pageSizeForColumns(10, columns),
            );
          },
        );
    }
  }
}
