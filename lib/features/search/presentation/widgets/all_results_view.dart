import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:musicare_metadata_host_sdk/musicare_metadata_host_sdk.dart';
import 'package:music_are/core/l10n/l10n_extension.dart';
import 'package:music_are/core/router/app_navigator.dart';
import 'package:music_are/core/widgets/bottom_sheets/track_options_bottom_sheet.dart';
import 'package:music_are/core/widgets/media/section_row.dart';
import 'package:music_are/core/widgets/media/track_matrix.dart';
import 'package:music_are/features/player/presentation/cubit/player_cubit.dart';

class AllResultsView extends StatelessWidget {
  final SearchResponse response;

  const AllResultsView({super.key, required this.response});

  @override
  Widget build(BuildContext context) {
    final tracks = response.tracks;
    final albums = response.albums;
    final artists = response.artists;
    final playlists = response.playlists;

    final activeTrackId = context.select<PlayerCubit, String?>(
      (c) => c.state.currentTrack?.id,
    );

    return ListView(
      padding: const EdgeInsets.symmetric(vertical: 12.0),
      children: [
        if (tracks.isNotEmpty)
          TrackMatrix(
            title: context.l10n.searchTracksHeader,
            tracks: tracks,
            activeTrackId: activeTrackId,
            onTrackTap: (track) {
              final index = tracks.indexOf(track);
              context.read<PlayerCubit>().playQueue(
                tracks,
                index: index >= 0 ? index : 0,
              );
            },
            onTrackOptionsTap: (track) {
              TrackOptionsBottomSheet.show(context, track);
            },
          ),
        if (albums.isNotEmpty)
          SectionRow(
            title: context.l10n.searchAlbumsHeader,
            items: albums,
            onItemTap: (item) => AppNavigator.toMediaDetail(context, item),
          ),
        if (artists.isNotEmpty)
          SectionRow(
            title: context.l10n.searchArtistsHeader,
            items: artists,
            onItemTap: (item) => AppNavigator.toMediaDetail(context, item),
          ),
        if (playlists.isNotEmpty)
          SectionRow(
            title: context.l10n.searchPlaylistsHeader,
            items: playlists,
            onItemTap: (item) => AppNavigator.toMediaDetail(context, item),
          ),
      ],
    );
  }
}
