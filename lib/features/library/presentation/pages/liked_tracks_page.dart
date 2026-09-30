import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:music_are/core/di/injection.dart';
import 'package:music_are/core/l10n/l10n_extension.dart';
import 'package:music_are/core/notice/notice_bus.dart';
import 'package:music_are/core/widgets/media/paginated_track_list.dart';
import 'package:music_are/core/widgets/media/section_slot.dart';
import 'package:music_are/core/widgets/skeletons/skeleton_track_list.dart';
import 'package:music_are/features/library/presentation/cubit/liked_tracks_cubit.dart';
import 'package:music_are/features/library/presentation/cubit/liked_tracks_state.dart';
import 'package:music_are/features/player/presentation/cubit/player_cubit.dart';
import 'package:music_are/features/plugin/metadata/data/services/metadata_plugin_engine.dart';

class LikedTracksPage extends StatelessWidget {
  const LikedTracksPage({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider<LikedTracksCubit>(
      create: (context) =>
          LikedTracksCubit(sl<MetadataPluginEngine>(), sl<NoticeBus>())..load(),
      child: const _LikedSongsView(),
    );
  }
}

class _LikedSongsView extends StatelessWidget {
  const _LikedSongsView();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(context.l10n.likedSongs)),
      body: BlocBuilder<LikedTracksCubit, LikedTracksState>(
        builder: (context, state) {
          return SectionSlot(
            section: state.tracks,
            loadingBuilder: (_) => const SkeletonTrackList(count: 8),
            emptyTitle: context.l10n.likedSongsEmptyTitle,
            emptyMessage: context.l10n.likedSongsEmptyMessage,
            emptyIcon: Icons.favorite_border_rounded,
            onRetry: () => context.read<LikedTracksCubit>().load(),
            contentBuilder: (context, result) => PaginatedTrackList(
              tracks: result.items,
              activeTrackId: context.select<PlayerCubit, String?>(
                (c) => c.state.currentTrack?.id,
              ),
              hasMore: result.items.length < result.total,
              isLoadingMore: state.tracks.isLoading,
              onLoadMore: () => context.read<LikedTracksCubit>().loadMore(),
              onTrackTap: (track) {
                final index = result.items.indexOf(track);
                context.read<PlayerCubit>().playQueue(
                  result.items,
                  index: index >= 0 ? index : 0,
                );
              },
            ),
          );
        },
      ),
    );
  }
}
