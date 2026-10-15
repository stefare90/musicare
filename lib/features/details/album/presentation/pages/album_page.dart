import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:musicare_metadata_host_sdk/musicare_metadata_host_sdk.dart';
import 'package:music_are/core/di/injection.dart';
import 'package:music_are/core/models/media_type.dart';
import 'package:music_are/core/notice/notice_bus.dart';
import 'package:music_are/core/widgets/bottom_sheets/bottom_sheets.dart';
import 'package:music_are/core/widgets/error_card.dart';
import 'package:music_are/core/widgets/media/sliver_media_scaffold.dart';
import 'package:music_are/core/widgets/media/sliver_track_list.dart';
import 'package:music_are/features/details/album/presentation/cubit/album_cubit.dart';
import 'package:music_are/features/details/album/presentation/cubit/album_state.dart';
import 'package:music_are/features/plugin/metadata/presentation/cubit/user_cubit.dart';
import 'package:music_are/features/library/presentation/utils/track_actions.dart';
import 'package:music_are/features/library/presentation/utils/collection_actions.dart';
import 'package:music_are/features/library/presentation/utils/share_actions.dart';
import 'package:music_are/features/player/presentation/cubit/player_cubit.dart';
import 'package:music_are/features/plugin/metadata/data/repositories/media_repository.dart';

class AlbumPage extends StatelessWidget {
  final Album album;

  const AlbumPage({super.key, required this.album});

  @override
  Widget build(BuildContext context) {
    return BlocProvider<AlbumCubit>(
      create: (context) =>
          AlbumCubit(sl<MediaRepository>(), sl<NoticeBus>())..loadAlbum(album),
      child: const _AlbumView(),
    );
  }
}

class _AlbumView extends StatefulWidget {
  const _AlbumView();

  @override
  State<_AlbumView> createState() => _AlbumViewState();
}

class _AlbumViewState extends State<_AlbumView> {
  @override
  void initState() {
    super.initState();
    final users = context.read<UserCubit>();
    if (!users.state.loaded.contains(MediaItemType.album)) {
      unawaited(users.refresh(MediaItemType.album, notify: false));
    }
  }

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<AlbumCubit, AlbumState>(
      builder: (context, state) {
        if (state is AlbumErrorState) {
          return SliverMediaScaffold(
            metadata: state.metadata,
            statusCard: ErrorCard(
              error: state.error,
              onRetry: () => context.read<AlbumCubit>().loadAlbum(state.album),
            ),
          );
        }
        if (state is AlbumLoadedState) {
          final isSaved = context.select<UserCubit, bool>(
            (c) => c.isAlbumSaved(state.album.id),
          );
          final isIndexLoaded = context.select<UserCubit, bool>(
            (c) => c.state.loaded.contains(MediaItemType.album),
          );
          final hasBulkTracks =
              state.tracks.items.isNotEmpty || state.hasMoreTracks;
          return SliverMediaScaffold(
            metadata: state.metadata,
            isSaved: isSaved,
            onSaveTap: isIndexLoaded
                ? () => context.read<UserCubit>().toggleAlbum(state.album)
                : null,
            onOptionsTap: () => AlbumOptionsBottomSheet.show(
              context,
              state.album,
              isSaved: isSaved,
              onPlayNext: hasBulkTracks
                  ? () => CollectionActions.playAllNext(
                      context,
                      loadAll: context.read<AlbumCubit>().loadAllTracks,
                      total: state.tracks.total,
                    )
                  : null,
              onAddToQueue: hasBulkTracks
                  ? () => CollectionActions.addAllToQueue(
                      context,
                      loadAll: context.read<AlbumCubit>().loadAllTracks,
                      total: state.tracks.total,
                    )
                  : null,
              onToggleSave: isIndexLoaded
                  ? () => context.read<UserCubit>().toggleAlbum(state.album)
                  : null,
              onShare: () => ShareActions.shareAlbum(state.album),
            ),            slivers: [
              SliverTrackList(
                tracks: state.tracks.items,
                listType: MediaType.album,
                hasMore: state.hasMoreTracks,
                loadMoreError: state is AlbumLoadMoreErrorState
                    ? state.error
                    : null,
                onLoadMore: () => context.read<AlbumCubit>().loadMoreTracks(),
                activeTrackId: context.select<PlayerCubit, String?>(
                  (c) => c.state.currentTrack?.id,
                ),
                onTrackTap: (track) {
                  final index = state.tracks.items.indexOf(track);
                  context.read<PlayerCubit>().playQueue(
                    state.tracks.items,
                    index: index >= 0 ? index : 0,
                    pending: context.read<AlbumCubit>().pendingSource(),
                  );
                },
                onTrackOptionsTap: (track) =>
                    TrackActions.showOptions(context, track),
              ),
            ],
          );
        }
        return SliverMediaScaffold(metadata: state.metadata, isLoading: true);
      },
    );
  }
}
