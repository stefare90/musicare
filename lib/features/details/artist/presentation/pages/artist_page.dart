import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:gyawun_metadata_sdk/metadata/models/artist.dart';
import 'package:music_are/core/di/injection.dart';
import 'package:music_are/core/l10n/l10n_extension.dart';
import 'package:music_are/core/models/media_type.dart';
import 'package:music_are/core/router/app_navigator.dart';
import 'package:music_are/core/widgets/bottom_sheets/bottom_sheets.dart';
import 'package:music_are/core/widgets/media/section_row.dart';
import 'package:music_are/core/widgets/media/sliver_media_scaffold.dart';
import 'package:music_are/core/widgets/media/sliver_track_list.dart';
import 'package:music_are/features/details/artist/presentation/cubit/artist_cubit.dart';
import 'package:music_are/features/details/artist/presentation/cubit/artist_state.dart';
import 'package:music_are/features/plugin/data/services/plugin_engine.dart';

class ArtistPage extends StatelessWidget {
  final Artist artist;

  const ArtistPage({super.key, required this.artist});

  @override
  Widget build(BuildContext context) {
    return BlocProvider<ArtistCubit>(
      create: (context) =>
          ArtistCubit(sl<PluginEngine>(), artist)..loadArtist(),
      child: const _ArtistView(),
    );
  }
}

class _ArtistView extends StatelessWidget {
  const _ArtistView();

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<ArtistCubit, ArtistState>(
      builder: (context, state) {
        if (state.isTotalFailure) {
          final errorToShow =
              state.firstError ?? Exception(context.l10n.noContentTitle);
          return SliverMediaScaffold(
            metadata: state.metadata,
            error: errorToShow,
            onRetry: () => context.read<ArtistCubit>().loadArtist(),
          );
        }
        return SliverMediaScaffold(
          metadata: state.metadata,
          isSaved: state.isSaved,
          onSaveTap: () => context.read<ArtistCubit>().toggleSave(),
          slivers: [
            SliverTrackList(
              title: context.l10n.popularTracks,
              tracks: state.topTracks.data.items,
              isLoading: state.topTracks.isLoading,
              error: state.topTracks.error,
              onRetry: () => context.read<ArtistCubit>().fetchTopTracks(),
              listType: MediaType.artist,
              onTrackOptionsTap: (track) =>
                  TrackOptionsBottomSheet.show(context, track),
            ),
            SliverToBoxAdapter(
              child: SectionRow(
                title: context.l10n.discography,
                items: state.albums.data.items,
                isLoading: state.albums.isLoading,
                error: state.albums.error,
                onRetry: () => context.read<ArtistCubit>().fetchAlbums(),
                onItemTap: (item) => AppNavigator.toMediaDetail(context, item),
              ),
            ),
            SliverToBoxAdapter(
              child: SectionRow(
                title: context.l10n.fansAlsoLike,
                items: state.related.data.items,
                isLoading: state.related.isLoading,
                error: state.related.error,
                onRetry: () => context.read<ArtistCubit>().fetchRelated(),
                onItemTap: (item) => AppNavigator.toMediaDetail(context, item),
              ),
            ),
            const SliverToBoxAdapter(child: SizedBox(height: 32)),
          ],
        );
      },
    );
  }
}
