import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:musicare_metadata_host_sdk/musicare_metadata_host_sdk.dart';
import 'package:music_are/core/l10n/l10n_extension.dart';
import 'package:music_are/core/models/section_state.dart';
import 'package:music_are/core/router/app_navigator.dart';
import 'package:music_are/core/widgets/library/library_collection_card.dart';
import 'package:music_are/core/widgets/media/media_card_error.dart';
import 'package:music_are/core/widgets/media/media_card_metrics.dart';
import 'package:music_are/core/widgets/media/paginated_media_grid.dart';
import 'package:music_are/features/library/presentation/cubit/library_cubit.dart';
import 'package:music_are/features/library/presentation/cubit/library_state.dart';

/// Playlists tab of the library.
///
/// *Liked Songs* is provider feedback, not a real playlist and with no artwork:
/// rather than a differently-shaped row it shares the grid as a special first
/// cell, so the page stays visually uniform.
class LibraryPlaylistsTab extends StatelessWidget {
  final SectionState<PaginatedResult<Playlist>> section;

  const LibraryPlaylistsTab({super.key, required this.section});

  @override
  Widget build(BuildContext context) {
    final items = section.data.items;
    final leading = <Widget>[
      LibraryCollectionCard(
        icon: Icons.favorite_rounded,
        title: context.l10n.likedSongs,
        subtitle: context.l10n.mediaTypePlaylist,
        onTap: () => AppNavigator.toLikedTracks(context),
      ),
    ];
    if (section.error != null && items.isEmpty) {
      leading.add(
        MediaCardError(
          title: context.l10n.libraryPlaylistsTab,
          error: section.error!,
          onRetry: () => context.read<LibraryCubit>().loadAll(),
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: () =>
          context.read<LibraryCubit>().refresh(LibrarySection.playlists),
      child: PaginatedMediaGrid(
        leading: leading,
        items: items,
        hasMore: items.length < section.data.total,
        isLoadingMore: section.isLoading,
        onLoadMore: () =>
            context.read<LibraryCubit>().loadMore(LibrarySection.playlists),
        onItemTap: (item) => AppNavigator.toMediaDetail(context, item),
        // Extra bottom room so the "New playlist" FAB never covers the last row.
        padding: EdgeInsets.fromLTRB(
          MediaCardMetrics.edgeInset,
          MediaCardMetrics.edgeInset,
          MediaCardMetrics.edgeInset,
          MediaCardMetrics.edgeInset + 72,
        ),
      ),
    );
  }
}
