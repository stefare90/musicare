import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:musicare_metadata_host_sdk/musicare_metadata_host_sdk.dart';
import 'package:music_are/core/di/injection.dart';
import 'package:music_are/core/l10n/l10n_extension.dart';
import 'package:music_are/core/models/media_type.dart';
import 'package:music_are/core/notice/notice_bus.dart';
import 'package:music_are/core/utils/playlist_ownership.dart';
import 'package:music_are/core/router/app_navigator.dart';
import 'package:music_are/core/widgets/bottom_sheets/bottom_sheets.dart';
import 'package:music_are/core/widgets/dialogs.dart';
import 'package:music_are/core/widgets/error_card.dart';
import 'package:music_are/core/widgets/media/sliver_media_scaffold.dart';
import 'package:music_are/core/widgets/media/sliver_track_list.dart';
import 'package:music_are/features/details/playlist/presentation/cubit/playlist_cubit.dart';
import 'package:music_are/features/details/playlist/presentation/cubit/playlist_state.dart';
import 'package:music_are/core/widgets/skeletons/skeleton_playlist_badge.dart';
import 'package:music_are/features/details/playlist/presentation/widgets/playlist_visibility_badge.dart';
import 'package:music_are/features/plugin/metadata/presentation/cubit/user_cubit.dart';
import 'package:music_are/features/library/presentation/utils/track_actions.dart';
import 'package:music_are/features/library/presentation/utils/collection_actions.dart';
import 'package:music_are/features/library/presentation/utils/share_actions.dart';
import 'package:music_are/features/player/presentation/cubit/player_cubit.dart';
import 'package:music_are/features/plugin/metadata/data/repositories/media_repository.dart';
import 'package:music_are/features/plugin/metadata/data/repositories/playlist_repository.dart';

class PlaylistPage extends StatelessWidget {
  final Playlist playlist;

  const PlaylistPage({super.key, required this.playlist});

  @override
  Widget build(BuildContext context) {
    return BlocProvider<PlaylistCubit>(
      create: (context) => PlaylistCubit(
        sl<MediaRepository>(),
        sl<PlaylistRepository>(),
        sl<NoticeBus>(),
        savedMedia: sl<UserSavedMediaIndex>(),
        edits: sl<UserPlaylistEdits>(),
      )..loadPlaylist(playlist),
      child: const _PlaylistView(),
    );
  }
}

class _PlaylistView extends StatefulWidget {
  const _PlaylistView();

  @override
  State<_PlaylistView> createState() => _PlaylistViewState();
}

class _PlaylistViewState extends State<_PlaylistView> {
  @override
  void initState() {
    super.initState();
    final users = context.read<UserCubit>();
    if (!users.state.loaded.contains(MediaItemType.playlist)) {
      unawaited(users.refresh(MediaItemType.playlist, notify: false));
    }
  }

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<PlaylistCubit, PlaylistState>(
      builder: (context, state) {
        final currentUserId = context.select<UserCubit, String?>(
          (c) => c.state.userId,
        );
        if (state is PlaylistErrorState) {
          return SliverMediaScaffold(
            metadata: state.metadata,
            statusCard: ErrorCard(
              error: state.error,
              onRetry: () =>
                  context.read<PlaylistCubit>().loadPlaylist(state.playlist),
            ),
          );
        }
        if (state is PlaylistLoadedState) {
          final playlist = state.playlist;
          final isOwned = playlist.isOwnedBy(currentUserId);
          final isIndexLoaded = context.select<UserCubit, bool>(
            (c) => c.state.loaded.contains(MediaItemType.playlist),
          );
          final isSaved =
              !isOwned &&
              isIndexLoaded &&
              context.select<UserCubit, bool>(
                (c) => c.isPlaylistSaved(playlist.id),
              );
          final hasBulkTracks =
              state.tracks.items.isNotEmpty || state.hasMoreTracks;
          return SliverMediaScaffold(
            metadata: state.metadata,
            headerBadge: isOwned
                ? PlaylistVisibilityBadge(isPublic: playlist.isPublic)
                : null,
            isSaved: isSaved,
            onSaveTap: isOwned || !isIndexLoaded
                ? null
                : () => context.read<UserCubit>().togglePlaylist(playlist),
            onOptionsTap: () => PlaylistOptionsBottomSheet.show(
              context,
              playlist,
              isSaved: isSaved,
              onPlayNext: hasBulkTracks
                  ? () => CollectionActions.playAllNext(
                      context,
                      loadAll: context.read<PlaylistCubit>().loadAllTracks,
                      total: state.tracks.total,
                    )
                  : null,
              onAddToQueue: hasBulkTracks
                  ? () => CollectionActions.addAllToQueue(
                      context,
                      loadAll: context.read<PlaylistCubit>().loadAllTracks,
                      total: state.tracks.total,
                    )
                  : null,
              onToggleSave: isOwned || !isIndexLoaded
                  ? null
                  : () => context.read<UserCubit>().togglePlaylist(playlist),
              onDelete: isOwned
                  ? () => _deletePlaylist(context, playlist)
                  : null,
              onShare: () => ShareActions.sharePlaylist(playlist),
            ),
            slivers: [
              SliverTrackList(
                tracks: state.tracks.items,
                listType: MediaType.playlist,
                hasMore: state.hasMoreTracks,
                loadMoreError: state is PlaylistLoadMoreErrorState
                    ? state.error
                    : null,
                onLoadMore: () =>
                    context.read<PlaylistCubit>().loadMoreTracks(),
                activeTrackId: context.select<PlayerCubit, String?>(
                  (c) => c.state.currentTrack?.id,
                ),
                onTrackTap: (track) {
                  final index = state.tracks.items.indexOf(track);
                  context.read<PlayerCubit>().playQueue(
                    state.tracks.items,
                    index: index >= 0 ? index : 0,
                    pending: context.read<PlaylistCubit>().pendingSource(),
                  );
                },
                onTrackOptionsTap: (track) =>
                    TrackActions.showOptions(context, track),
                confirmTrackDismiss: isOwned
                    ? (track) => Dialogs.confirm(
                        context,
                        title: context.l10n.removeFromPlaylistTitle,
                        message: context.l10n.removeFromPlaylistMessage(
                          track.name,
                        ),
                        confirmLabel: context.l10n.remove,
                      )
                    : null,
                onTrackDismissed: isOwned
                    ? (track) => _removeTrack(context, playlist, track)
                    : null,
              ),
            ],
          );
        }
        final loadingPlaylist = state is PlaylistLoadingState
            ? state.playlist
            : null;
        return SliverMediaScaffold(
          metadata: state.metadata,
          isLoading: true,
          headerBadge: (loadingPlaylist?.isOwnedBy(currentUserId) ?? false)
              ? const SkeletonPlaylistBadge()
              : null,
        );
      },
    );
  }

  Future<void> _deletePlaylist(BuildContext context, Playlist playlist) async {
    final confirmed = await Dialogs.confirm(
      context,
      title: context.l10n.deletePlaylistTitle,
      message: context.l10n.deletePlaylistMessage(playlist.name),
      confirmLabel: context.l10n.deletePlaylist,
    );
    if (!confirmed || !context.mounted) return;

    final cubit = context.read<PlaylistCubit>();
    final deleted = await cubit.deletePlaylist();
    if (!deleted || !context.mounted) return;

    AppNavigator.toLibrary(context);
  }

  Future<void> _removeTrack(
    BuildContext context,
    Playlist playlist,
    Track track,
  ) async {
    final removed = await context.read<PlaylistCubit>().removeTrack(track);
    if (!removed || !context.mounted) return;

    sl<NoticeBus>().emit(
      Notice.message(context.l10n.removedFromPlaylist(playlist.name)),
    );
  }
}
