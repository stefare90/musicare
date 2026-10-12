import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:musicare_metadata_host_sdk/musicare_metadata_host_sdk.dart';
import 'package:music_are/core/di/injection.dart';
import 'package:music_are/core/l10n/l10n_extension.dart';
import 'package:music_are/core/notice/notice_bus.dart';
import 'package:music_are/core/widgets/dialogs.dart';
import 'package:music_are/core/widgets/media/paginated_track_list.dart';
import 'package:music_are/core/widgets/media/section_slot.dart';
import 'package:music_are/core/widgets/skeletons/skeleton_track_list.dart';
import 'package:music_are/features/library/presentation/cubit/liked_tracks_cubit.dart';
import 'package:music_are/features/library/presentation/cubit/liked_tracks_state.dart';
import 'package:music_are/features/library/presentation/utils/track_actions.dart';
import 'package:music_are/features/player/presentation/cubit/player_cubit.dart';
import 'package:music_are/features/plugin/metadata/data/repositories/library_repository.dart';
import 'package:music_are/features/plugin/metadata/presentation/cubit/user_cubit.dart';

class LikedTracksPage extends StatelessWidget {
  const LikedTracksPage({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider<LikedTracksCubit>(
      create: (context) =>
          LikedTracksCubit(
            sl<LibraryRepository>(),
            sl<NoticeBus>(),
            savedMedia: sl<UserSavedMediaIndex>(),
            favorites: sl<UserFavorites>(),
          )..load(),
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
                    pending:
                        context.read<LikedTracksCubit>().pendingSource(),
                  );
                },
                onTrackOptionsTap: (track) =>
                    TrackActions.showOptions(context, track),
                confirmTrackDismiss: (track) => Dialogs.confirm(
                  context,
                  title: context.l10n.removeFromFavoritesTitle,
                  message: context.l10n.removeFromFavoritesMessage(track.name),
                  confirmLabel: context.l10n.remove,
                ),
                onTrackDismissed: (track) => _removeTrack(context, track),
              ),
            );
        },
      ),
    );
  }

  Future<void> _removeTrack(BuildContext context, Track track) async {
    await context.read<LikedTracksCubit>().removeTrack(track);
  }
}
