import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:gyawun_metadata_sdk/metadata/models/playlist.dart';
import 'package:music_are/core/di/injection.dart';
import 'package:music_are/core/models/media_type.dart';
import 'package:music_are/core/widgets/bottom_sheets/bottom_sheets.dart';
import 'package:music_are/core/widgets/dialogs.dart';
import 'package:music_are/core/widgets/media/sliver_media_scaffold.dart';
import 'package:music_are/core/widgets/media/sliver_track_list.dart';
import 'package:music_are/features/details/playlist/presentation/cubit/playlist_cubit.dart';
import 'package:music_are/features/details/playlist/presentation/cubit/playlist_state.dart';
import 'package:music_are/features/plugin/data/services/plugin_engine.dart';
import 'package:music_are/features/plugin/presentation/utils/exception_localizer.dart';

class PlaylistPage extends StatelessWidget {
  final Playlist playlist;

  const PlaylistPage({super.key, required this.playlist});

  @override
  Widget build(BuildContext context) {
    return BlocProvider<PlaylistCubit>(
      create: (context) =>
          PlaylistCubit(sl<PluginEngine>())..loadPlaylist(playlist),
      child: const _PlaylistView(),
    );
  }
}

class _PlaylistView extends StatelessWidget {
  const _PlaylistView();

  @override
  Widget build(BuildContext context) {
    return BlocConsumer<PlaylistCubit, PlaylistState>(
      listenWhen: (prev, curr) =>
          curr is PlaylistLoadedState && curr.refreshError != null,
      listener: (context, state) {
        if (state is PlaylistLoadedState && state.refreshError != null) {
          Dialogs.showErrorSnackBar(
            context,
            message: state.refreshError!.toLocalizedString(context),
          );
        }
      },
      builder: (context, state) {
        if (state is PlaylistErrorState) {
          return SliverMediaScaffold(
            metadata: state.metadata,
            error: state.error,
            onRetry: () =>
                context.read<PlaylistCubit>().loadPlaylist(state.playlist),
          );
        }
        if (state is PlaylistLoadedState) {
          return SliverMediaScaffold(
            metadata: state.metadata,
            isSaved: state.isSaved,
            onSaveTap: () => context.read<PlaylistCubit>().toggleSave(),
            onOptionsTap: () => PlaylistOptionsBottomSheet.show(
              context,
              state.playlist,
              onToggleSave: () => context.read<PlaylistCubit>().toggleSave(),
            ),
            slivers: [
              SliverTrackList(
                tracks: state.tracks.items,
                listType: MediaType.playlist,
                hasMore: state.hasMoreTracks,
                onLoadMore: () =>
                    context.read<PlaylistCubit>().loadMoreTracks(),
                onTrackOptionsTap: (track) =>
                    TrackOptionsBottomSheet.show(context, track),
              ),
            ],
          );
        }
        return SliverMediaScaffold(metadata: state.metadata, isLoading: true);
      },
    );
  }
}
