import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:gyawun_metadata_sdk/metadata/models/album.dart';
import 'package:gyawun_metadata_sdk/metadata/models/artist.dart';
import 'package:gyawun_metadata_sdk/metadata/models/playlist.dart';
import 'package:gyawun_metadata_sdk/metadata/models/track.dart';
import 'package:music_are/core/di/injection.dart';
import 'package:music_are/core/l10n/l10n_extension.dart';
import 'package:music_are/core/router/app_navigator.dart';
import 'package:music_are/core/theme/theme_extension.dart';
import 'package:music_are/core/widgets/bottom_sheets/track_options_bottom_sheet.dart';
import 'package:music_are/core/widgets/error_card.dart';
import 'package:music_are/core/widgets/info_card.dart';
import 'package:music_are/core/widgets/media/media_card.dart';
import 'package:music_are/core/widgets/media/media_card_metrics.dart';
import 'package:music_are/core/widgets/media/section_row.dart';
import 'package:music_are/core/widgets/media/track_list_tile.dart';
import 'package:music_are/core/widgets/media/track_matrix.dart';
import 'package:music_are/core/widgets/skeletons/shimmer_box.dart';
import 'package:music_are/core/widgets/skeletons/skeleton_media_grid.dart';
import 'package:music_are/core/widgets/skeletons/skeleton_search_all.dart';
import 'package:music_are/core/widgets/skeletons/skeleton_track_list.dart';
import 'package:music_are/features/player/presentation/cubit/player_cubit.dart';
import 'package:music_are/features/plugin/metadata/data/services/metadata_plugin_engine.dart';
import 'package:music_are/features/search/presentation/cubit/search_cubit.dart';
import 'package:music_are/features/search/presentation/cubit/search_state.dart';

class SearchPage extends StatelessWidget {
  const SearchPage({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider<SearchCubit>(
      create: (context) =>
          SearchCubit(sl<MetadataPluginEngine>())..loadChips(),
      child: const _SearchView(),
    );
  }
}

class _SearchView extends StatefulWidget {
  const _SearchView();

  @override
  State<_SearchView> createState() => _SearchViewState();
}

class _SearchViewState extends State<_SearchView> {
  late final TextEditingController _controller;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        titleSpacing: 16.0,
        title: _SearchBar(controller: _controller),
        bottom: const PreferredSize(
          preferredSize: Size.fromHeight(48.0),
          child: _SearchChipsBar(),
        ),
      ),
      body: const _SearchResultsBody(),
    );
  }
}

class _SearchBar extends StatelessWidget {
  final TextEditingController controller;

  const _SearchBar({required this.controller});

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: controller,
      autofocus: false,
      textInputAction: TextInputAction.search,
      decoration: InputDecoration(
        hintText: context.l10n.searchHint,
        prefixIcon: const Icon(Icons.search),
        suffixIcon: ValueListenableBuilder<TextEditingValue>(
          valueListenable: controller,
          builder: (context, value, _) {
            if (value.text.isEmpty) return const SizedBox.shrink();
            return IconButton(
              icon: const Icon(Icons.clear),
              onPressed: () {
                controller.clear();
                context.read<SearchCubit>().onQueryChanged('');
              },
            );
          },
        ),
        isDense: true,
        filled: true,
        fillColor: context.colorScheme.surfaceContainerHighest.withValues(alpha: 0.5),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(28.0),
          borderSide: BorderSide.none,
        ),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 16.0,
          vertical: 10.0,
        ),
      ),
      onChanged: (text) {
        context.read<SearchCubit>().onQueryChanged(text);
      },
      onSubmitted: (text) {
        context.read<SearchCubit>().search(text);
      },
    );
  }
}

class _SearchChipsBar extends StatelessWidget {
  const _SearchChipsBar();

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<SearchCubit, SearchState>(
      buildWhen: (prev, curr) =>
          prev.chips != curr.chips ||
          prev.selectedChip != curr.selectedChip,
      builder: (context, state) {
        final availableChips = ['All', ...state.chips];
        final selectedChip = state.selectedChip ?? 'All';

        return SizedBox(
          height: 48.0,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 6.0),
            itemCount: availableChips.length,
            separatorBuilder: (context, index) => const SizedBox(width: 8.0),
            itemBuilder: (context, index) {
              final chip = availableChips[index];
              final isSelected =
                  chip.toLowerCase() == selectedChip.toLowerCase();

              return FilterChip(
                label: Text(
                  chip == 'All' ? context.l10n.searchAllChip : chip,
                ),
                selected: isSelected,
                showCheckmark: false,
                selectedColor: context.colorScheme.primary,
                labelStyle: TextStyle(
                  color: isSelected
                      ? context.colorScheme.onPrimary
                      : context.colorScheme.onSurface,
                ),
                onSelected: (_) {
                  context.read<SearchCubit>().selectChip(
                        chip == 'All' ? null : chip,
                      );
                },
              );
            },
          ),
        );
      },
    );
  }
}

class _SearchResultsBody extends StatelessWidget {
  const _SearchResultsBody();

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final columns = MediaCardMetrics.gridColumns(constraints.maxWidth);
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (!context.mounted) return;
          context.read<SearchCubit>().updateGridColumns(columns);
        });

        return BlocBuilder<SearchCubit, SearchState>(
          builder: (context, state) {
            if (state.isEmptyQuery) {
              return _ScrollableCentered(
                child: InfoCard(
                  title: context.l10n.searchEmptyTitle,
                  message: context.l10n.searchEmptySubtitle,
                  icon: Icons.search,
                ),
              );
            }

            if (state.error != null) {
              return _ScrollableCentered(
                child: ErrorCard(
                  error: state.error!,
                  onRetry: () => context.read<SearchCubit>().retry(),
                ),
              );
            }

            if (state.isLoading) {
              return const _SearchLoadingView();
            }

            if (!state.hasResults) {
              return _ScrollableCentered(
                child: InfoCard(
                  title: context.l10n.searchNoResultsTitle,
                  message: context.l10n.searchNoResultsSubtitle,
                  icon: Icons.music_off,
                ),
              );
            }

            if (state.isAllCategory) {
              return _AllResultsView(response: state.allResults!);
            }

            return _CategoryResultsView(state: state);
          },
        );
      },
    );
  }
}

/// Keeps its [child] vertically centered when there is room, and lets it
/// scroll when the viewport is too short (e.g. landscape or keyboard open),
/// so non-list states can never trigger a `RenderFlex` overflow.
class _ScrollableCentered extends StatelessWidget {
  final Widget child;

  const _ScrollableCentered({required this.child});

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) => SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        child: ConstrainedBox(
          constraints: BoxConstraints(minHeight: constraints.maxHeight),
          child: Center(child: child),
        ),
      ),
    );
  }
}

class _SearchLoadingView extends StatelessWidget {
  const _SearchLoadingView();

  @override
  Widget build(BuildContext context) {
    final category = context.select<SearchCubit, SearchCategory>(
      (c) => c.state.resolvedCategory,
    );

    switch (category) {
      case SearchCategory.all:
        return const SkeletonSearchAll();
      case SearchCategory.tracks:
        return ListView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.symmetric(vertical: 8.0),
          children: const [
            SkeletonTrackList(count: 10),
          ],
        );
      case SearchCategory.albums:
      case SearchCategory.artists:
      case SearchCategory.playlists:
        return LayoutBuilder(
          builder: (context, constraints) {
            final columns =
                MediaCardMetrics.gridColumns(constraints.maxWidth);
            return SkeletonMediaGrid(
              itemCount: MediaCardMetrics.pageSizeForColumns(10, columns),
            );
          },
        );
    }
  }
}

class _AllResultsView extends StatelessWidget {
  final dynamic response;

  const _AllResultsView({required this.response});

  @override
  Widget build(BuildContext context) {
    final tracks = (response.tracks as List<Track>?) ?? [];
    final albums = (response.albums as List<Album>?) ?? [];
    final artists = (response.artists as List<Artist>?) ?? [];
    final playlists = (response.playlists as List<Playlist>?) ?? [];

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

class _CategoryResultsView extends StatelessWidget {
  final SearchState state;

  const _CategoryResultsView({required this.state});

  @override
  Widget build(BuildContext context) {
    final activeTrackId = context.select<PlayerCubit, String?>(
      (c) => c.state.currentTrack?.id,
    );

    switch (state.resolvedCategory) {
      case SearchCategory.tracks:
        final items = state.trackResults?.items ?? [];
        return NotificationListener<ScrollNotification>(
          onNotification: (scrollInfo) {
            if (state.hasMore &&
                !state.isLoadingMore &&
                state.loadMoreError == null &&
                scrollInfo.metrics.extentAfter < 200) {
              context.read<SearchCubit>().loadMore();
            }
            return false;
          },
          child: ListView.builder(
            padding: const EdgeInsets.symmetric(vertical: 8.0),
            itemCount: items.length + (state.isLoadingMore ? 1 : 0),
            itemBuilder: (context, index) {
              if (index >= items.length) {
                return const Center(
                  child: Padding(
                    padding: EdgeInsets.all(16.0),
                    child: CircularProgressIndicator(),
                  ),
                );
              }
              final track = items[index];
              return TrackListTile(
                track: track,
                isPlaying: track.id == activeTrackId,
                onTap: () {
                  context.read<PlayerCubit>().playQueue(
                        items,
                        index: index,
                      );
                },
                onOptionsTap: () {
                  TrackOptionsBottomSheet.show(context, track);
                },
              );
            },
          ),
        );

      case SearchCategory.albums:
        return _PaginatedMediaGrid(
          items: state.albumResults?.items ?? [],
          hasMore: state.hasMore,
          isLoadingMore: state.isLoadingMore,
        );

      case SearchCategory.artists:
        return _PaginatedMediaGrid(
          items: state.artistResults?.items ?? [],
          hasMore: state.hasMore,
          isLoadingMore: state.isLoadingMore,
        );

      case SearchCategory.playlists:
        return _PaginatedMediaGrid(
          items: state.playlistResults?.items ?? [],
          hasMore: state.hasMore,
          isLoadingMore: state.isLoadingMore,
        );

      case SearchCategory.all:
        return const SizedBox.shrink();
    }
  }
}

class _PaginatedMediaGrid extends StatelessWidget {
  final List<Object> items;
  final bool hasMore;
  final bool isLoadingMore;

  const _PaginatedMediaGrid({
    required this.items,
    required this.hasMore,
    required this.isLoadingMore,
  });

  @override
  Widget build(BuildContext context) {
    return NotificationListener<ScrollNotification>(
      onNotification: (scrollInfo) {
        if (hasMore &&
            !isLoadingMore &&
            scrollInfo.metrics.extentAfter < 200) {
          context.read<SearchCubit>().loadMore();
        }
        return false;
      },
      child: LayoutBuilder(
        builder: (context, constraints) {
          final textBlockHeight = MediaCardMetrics.textBlockHeight(context);
          final delegate = MediaCardMetrics.gridDelegate(
            maxWidth: constraints.maxWidth,
            textBlockHeight: textBlockHeight,
          );
          final columns = delegate.crossAxisCount;
          final cellWidth = MediaCardMetrics.gridCellWidth(
            constraints.maxWidth,
            columns,
          );
          final cellHeight = cellWidth + textBlockHeight;
          // A whole row of skeletons keeps the progressive loading coherent
          // with the initial grid skeleton instead of showing a lone spinner.
          final skeletonCount = isLoadingMore ? columns : 0;

          return GridView.builder(
            padding: const EdgeInsets.all(MediaCardMetrics.edgeInset),
            gridDelegate: delegate,
            itemCount: items.length + skeletonCount,
            itemBuilder: (context, index) {
              if (index >= items.length) {
                return ShimmerBox(
                  width: cellWidth,
                  height: cellHeight,
                  borderRadius: BorderRadius.circular(
                    MediaCardMetrics.radius,
                  ),
                );
              }
              final item = items[index];
              return MediaCard(
                item: item,
                onTap: () => AppNavigator.toMediaDetail(context, item),
              );
            },
          );
        },
      ),
    );
  }
}
