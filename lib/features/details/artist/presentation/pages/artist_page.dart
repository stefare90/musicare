import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:musicare_metadata_host_sdk/musicare_metadata_host_sdk.dart';
import 'package:music_are/core/di/injection.dart';
import 'package:music_are/core/l10n/l10n_extension.dart';
import 'package:music_are/core/notice/notice_bus.dart';
import 'package:music_are/core/router/app_navigator.dart';
import 'package:music_are/core/widgets/bottom_sheets/bottom_sheets.dart';
import 'package:music_are/core/widgets/error_card.dart';
import 'package:music_are/core/widgets/media/section_row.dart';
import 'package:music_are/core/widgets/media/sliver_media_scaffold.dart';
import 'package:music_are/core/widgets/media/track_matrix.dart';
import 'package:music_are/features/details/artist/presentation/cubit/artist_cubit.dart';
import 'package:music_are/features/details/artist/presentation/cubit/artist_state.dart';
import 'package:music_are/features/plugin/metadata/presentation/cubit/user_cubit.dart';
import 'package:music_are/features/library/presentation/utils/track_actions.dart';
import 'package:music_are/features/library/presentation/utils/collection_actions.dart';
import 'package:music_are/features/library/presentation/utils/share_actions.dart';
import 'package:music_are/features/player/presentation/cubit/player_cubit.dart';
import 'package:music_are/features/plugin/metadata/data/repositories/media_repository.dart';

class ArtistPage extends StatelessWidget {
  final Artist artist;

  const ArtistPage({super.key, required this.artist});

  @override
  Widget build(BuildContext context) {
    return BlocProvider<ArtistCubit>(
      create: (context) =>
          ArtistCubit(sl<MediaRepository>(), sl<NoticeBus>(), artist)
            ..loadArtist(),
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
            statusCard: ErrorCard(
              error: errorToShow,
              onRetry: () => context.read<ArtistCubit>().loadArtist(),
            ),
          );
        }
        final isSaved = context.select<UserCubit, bool>(
          (c) => c.isArtistSaved(state.artist.id),
        );
        final topTracks = state.topTracks.data;
        final hasBulkTracks =
            topTracks.items.isNotEmpty || topTracks.items.length < topTracks.total;
        return SliverMediaScaffold(
          metadata: state.metadata,
          isSaved: isSaved,
          onSaveTap: () =>
              context.read<UserCubit>().toggleArtist(state.artist),
          onOptionsTap: () => ArtistOptionsBottomSheet.show(
                  context,
                  state.artist,
                  isSaved: isSaved,
                  onToggleSave: () =>
                      context.read<UserCubit>().toggleArtist(state.artist),
                  onShare: () => ShareActions.shareArtist(state.artist),
                  onPlayNext: hasBulkTracks
                      ? () => CollectionActions.playAllNext(
                          context,
                          loadAll: context.read<ArtistCubit>().loadAllTopTracks,
                          total: topTracks.total,
                        )
                      : null,
                  onAddToQueue: hasBulkTracks
                      ? () => CollectionActions.addAllToQueue(
                          context,
                          loadAll: context.read<ArtistCubit>().loadAllTopTracks,
                          total: topTracks.total,
                        )
                      : null,
                ),
          slivers: [
            SliverToBoxAdapter(
              child: TrackMatrix(
                title: context.l10n.popularTracks,
                tracks: state.topTracks.data.items,
                activeTrackId: context.select<PlayerCubit, String?>(
                  (c) => c.state.currentTrack?.id,
                ),
                onTrackTap: (track) {
                  final index = state.topTracks.data.items.indexOf(track);
                  context.read<PlayerCubit>().playQueue(
                    state.topTracks.data.items,
                    index: index >= 0 ? index : 0,
                    pending: context
                        .read<ArtistCubit>()
                        .pendingTopTracksSource(),
                  );
                },
                isLoading:
                    state.topTracks.isLoading &&
                    state.topTracks.data.items.isEmpty,
                isLoadingMore:
                    state.topTracks.isLoading &&
                    state.topTracks.data.items.isNotEmpty,
                hasMore:
                    state.topTracks.data.items.length <
                    state.topTracks.data.total,
                error: state.topTracks.data.items.isEmpty
                    ? state.topTracks.error
                    : null,
                loadMoreError: state.topTracks.data.items.isNotEmpty
                    ? state.topTracks.error
                    : null,
                onRetry: () => context.read<ArtistCubit>().fetchTopTracks(),
                onLoadMore: () =>
                    context.read<ArtistCubit>().fetchMoreTopTracks(),
                onTrackOptionsTap: (track) =>
                    TrackActions.showOptions(context, track),
              ),
            ),
            SliverToBoxAdapter(
              child: SectionRow(
                title: context.l10n.discography,
                items: state.albums.data.items,
                isLoading:
                    state.albums.isLoading && state.albums.data.items.isEmpty,
                isLoadingMore:
                    state.albums.isLoading &&
                    state.albums.data.items.isNotEmpty,
                hasMore:
                    state.albums.data.items.length < state.albums.data.total,
                error: state.albums.data.items.isEmpty
                    ? state.albums.error
                    : null,
                loadMoreError: state.albums.data.items.isNotEmpty
                    ? state.albums.error
                    : null,
                onRetry: () => context.read<ArtistCubit>().fetchAlbums(),
                onLoadMore: () => context.read<ArtistCubit>().fetchMoreAlbums(),
                onItemTap: (item) => AppNavigator.toMediaDetail(context, item),
              ),
            ),
            SliverToBoxAdapter(
              child: SectionRow(
                title: context.l10n.fansAlsoLike,
                items: state.related.data.items,
                isLoading:
                    state.related.isLoading && state.related.data.items.isEmpty,
                isLoadingMore:
                    state.related.isLoading &&
                    state.related.data.items.isNotEmpty,
                hasMore:
                    state.related.data.items.length < state.related.data.total,
                error: state.related.data.items.isEmpty
                    ? state.related.error
                    : null,
                loadMoreError: state.related.data.items.isNotEmpty
                    ? state.related.error
                    : null,
                onRetry: () => context.read<ArtistCubit>().fetchRelated(),
                onLoadMore: () =>
                    context.read<ArtistCubit>().fetchMoreRelated(),
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
