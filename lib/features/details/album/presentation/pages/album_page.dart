import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:gyawun_metadata_sdk/metadata/models/album.dart';
import 'package:music_are/core/di/injection.dart';
import 'package:music_are/core/models/media_type.dart';
import 'package:music_are/core/widgets/bottom_sheets/bottom_sheets.dart';
import 'package:music_are/core/widgets/media/sliver_media_scaffold.dart';
import 'package:music_are/core/widgets/media/sliver_track_list.dart';
import 'package:music_are/features/details/album/presentation/cubit/album_cubit.dart';
import 'package:music_are/features/details/album/presentation/cubit/album_state.dart';
import 'package:music_are/features/plugin/data/services/plugin_engine.dart';

class AlbumPage extends StatelessWidget {
  final Album album;

  const AlbumPage({super.key, required this.album});

  @override
  Widget build(BuildContext context) {
    return BlocProvider<AlbumCubit>(
      create: (context) => AlbumCubit(sl<PluginEngine>())..loadAlbum(album),
      child: const _AlbumView(),
    );
  }
}

class _AlbumView extends StatelessWidget {
  const _AlbumView();

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<AlbumCubit, AlbumState>(
      builder: (context, state) {
        if (state is AlbumErrorState) {
          return SliverMediaScaffold(
            metadata: state.metadata,
            error: state.error,
            onRetry: () => context.read<AlbumCubit>().loadAlbum(state.album),
          );
        }
        if (state is AlbumLoadedState) {
          return SliverMediaScaffold(
            metadata: state.metadata,
            isSaved: state.isSaved,
            onSaveTap: () => context.read<AlbumCubit>().toggleSave(),
            onOptionsTap: () => AlbumOptionsBottomSheet.show(
              context,
              state.album,
              onToggleSave: () => context.read<AlbumCubit>().toggleSave(),
            ),
            slivers: [
              SliverTrackList(
                tracks: state.tracks.items,
                listType: MediaType.album,
                hasMore: state.hasMoreTracks,
                loadMoreError: state is AlbumLoadMoreErrorState
                    ? state.error
                    : null,
                onLoadMore: () => context.read<AlbumCubit>().loadMoreTracks(),
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
