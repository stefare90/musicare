import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:musicare_metadata_host_sdk/musicare_metadata_host_sdk.dart';
import 'package:music_are/core/di/injection.dart';
import 'package:music_are/core/l10n/l10n_extension.dart';
import 'package:music_are/core/models/media_type.dart';
import 'package:music_are/core/notice/notice_bus.dart';
import 'package:music_are/core/widgets/bottom_sheets/bottom_sheets.dart';
import 'package:music_are/core/widgets/dialogs.dart';
import 'package:music_are/core/widgets/error_card.dart';
import 'package:music_are/core/widgets/media/sliver_media_scaffold.dart';
import 'package:music_are/core/widgets/media/sliver_track_list.dart';
import 'package:music_are/features/details/playlist/presentation/cubit/playlist_cubit.dart';
import 'package:music_are/features/details/playlist/presentation/cubit/playlist_state.dart';
import 'package:music_are/features/plugin/metadata/presentation/cubit/saved_media_cubit.dart';
import 'package:music_are/features/library/presentation/utils/track_actions.dart';
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
      )..loadPlaylist(playlist),
      child: const _PlaylistView(),
    );
  }
}

class _PlaylistView extends StatelessWidget {
  const _PlaylistView();

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<PlaylistCubit, PlaylistState>(
      builder: (context, state) {
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
          final isSaved = context.select<SavedMediaCubit, bool>(
            (c) => c.isPlaylistSaved(state.playlist.id),
          );
          return SliverMediaScaffold(
            metadata: state.metadata,
            isSaved: isSaved,
            onSaveTap: () =>
                context.read<SavedMediaCubit>().togglePlaylist(state.playlist),
            onOptionsTap: () => PlaylistOptionsBottomSheet.show(
              context,
              state.playlist,
              isSaved: isSaved,
              onToggleSave: () => context
                  .read<SavedMediaCubit>()
                  .togglePlaylist(state.playlist),
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
                  );
                },
                onTrackOptionsTap: (track) =>
                    TrackActions.showOptions(context, track),
                confirmTrackDismiss: (track) => Dialogs.confirm(
                  context,
                  title: context.l10n.removeFromPlaylistTitle,
                  message: context.l10n.removeFromPlaylistMessage(track.name),
                  confirmLabel: context.l10n.remove,
                ),
                onTrackDismissed: (track) =>
                    _removeTrack(context, state.playlist, track),
              ),
            ],
          );
        }
        return SliverMediaScaffold(metadata: state.metadata, isLoading: true);
      },
    );
  }

  Future<void> _removeTrack(
    BuildContext context,
    Playlist playlist,
    Track track,
  ) async {
    final cubit = context.read<PlaylistCubit>();
    final messenger = ScaffoldMessenger.of(context);
    final removed = await cubit.removeTrack(track);
    if (!removed || !context.mounted) return;

    messenger.showSnackBar(
      SnackBar(
        content: Text(context.l10n.removedFromPlaylist(playlist.name)),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }
}
