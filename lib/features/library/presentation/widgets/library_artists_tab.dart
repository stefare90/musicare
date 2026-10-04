import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:musicare_metadata_host_sdk/musicare_metadata_host_sdk.dart';
import 'package:music_are/core/l10n/l10n_extension.dart';
import 'package:music_are/core/models/section_state.dart';
import 'package:music_are/core/router/app_navigator.dart';
import 'package:music_are/core/widgets/media/paginated_media_grid.dart';
import 'package:music_are/core/widgets/media/section_slot.dart';
import 'package:music_are/core/widgets/skeletons/skeleton_media_grid.dart';
import 'package:music_are/features/library/presentation/cubit/library_cubit.dart';
import 'package:music_are/features/library/presentation/cubit/library_state.dart';

class LibraryArtistsTab extends StatelessWidget {
  final SectionState<PaginatedResult<Artist>> section;

  const LibraryArtistsTab({super.key, required this.section});

  @override
  Widget build(BuildContext context) {
    return RefreshIndicator(
      onRefresh: () => context.read<LibraryCubit>().refresh(LibrarySection.artists),
      child: SectionSlot<Artist>(
        section: section,
        loadingBuilder: (_) => const SkeletonMediaGrid(),
        emptyTitle: context.l10n.libraryArtistsEmpty,
        emptyMessage: context.l10n.libraryArtistsEmptyMessage,
        emptyIcon: Icons.person_rounded,
        onRetry: () => context.read<LibraryCubit>().loadAll(),
        contentBuilder: (context, result) => PaginatedMediaGrid(
          items: result.items,
          hasMore: result.items.length < result.total,
          isLoadingMore: section.isLoading,
          onLoadMore: () =>
              context.read<LibraryCubit>().loadMore(LibrarySection.artists),
          onItemTap: (item) => AppNavigator.toMediaDetail(context, item),
        ),
      ),
    );
  }
}
