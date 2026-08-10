import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:gyawun_metadata_sdk/metadata/models/album.dart';
import 'package:music_are/core/di/injection.dart';
import 'package:music_are/core/models/media_type.dart';
import 'package:music_are/core/widgets/bottom_sheets/bottom_sheets.dart';
import 'package:music_are/core/widgets/dialogs.dart';
import 'package:music_are/core/widgets/media/sliver_media_detail_layout.dart';
import 'package:music_are/features/details/album/presentation/cubit/album_cubit.dart';
import 'package:music_are/features/details/album/presentation/cubit/album_state.dart';
import 'package:music_are/features/plugin/data/services/plugin_engine.dart';
import 'package:music_are/features/plugin/presentation/utils/exception_localizer.dart';

class AlbumPage extends StatelessWidget {
  final Album album;

  const AlbumPage({super.key, required this.album});

  @override
  Widget build(BuildContext context) {
    return BlocProvider<AlbumCubit>(
      create: (context) => AlbumCubit(sl<PluginEngine>())..loadAlbum(album),
      child: BlocConsumer<AlbumCubit, AlbumState>(
        listenWhen: (prev, curr) =>
            curr is AlbumLoadedState && curr.refreshError != null,
        listener: (context, state) {
          if (state is AlbumLoadedState && state.refreshError != null) {
            Dialogs.showErrorSnackBar(
              context,
              message: state.refreshError!.toLocalizedString(context),
            );
          }
        },
        builder: (context, state) {
          if (state is AlbumErrorState) {
            return SliverMediaDetailLayout(
              metadata: state.metadata,
              error: state.error,
              listType: MediaType.album,
              onRetry: () => context.read<AlbumCubit>().loadAlbum(album),
            );
          }
          if (state is AlbumLoadedState) {
            return SliverMediaDetailLayout(
              metadata: state.metadata,
              isSaved: state.isSaved,
              tracks: state.tracks.items,
              hasMoreTracks: state.hasMoreTracks,
              listType: MediaType.album,
              onRetry: () => context.read<AlbumCubit>().loadAlbum(album),
              onLoadMore: () => context.read<AlbumCubit>().loadMoreTracks(),
              onSaveTap: () => context.read<AlbumCubit>().toggleSave(),
              onOptionsTap: () => AlbumOptionsBottomSheet.show(
                context,
                state.album,
                onToggleSave: () => context.read<AlbumCubit>().toggleSave(),
              ),
              onTrackOptionsTap: (track) =>
                  TrackOptionsBottomSheet.show(context, track),
            );
          }
          return SliverMediaDetailLayout(
            metadata: state.metadata,
            isLoading: true,
            listType: MediaType.album,
          );
        },
      ),
    );
  }
}
