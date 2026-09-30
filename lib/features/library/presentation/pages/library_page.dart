import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:musicare_metadata_host_sdk/musicare_metadata_host_sdk.dart';
import 'package:music_are/core/di/injection.dart';
import 'package:music_are/core/l10n/l10n_extension.dart';
import 'package:music_are/core/notice/notice_bus.dart';
import 'package:music_are/core/router/app_navigator.dart';
import 'package:music_are/core/widgets/info_card.dart';
import 'package:music_are/core/widgets/library/library_collection_card.dart';
import 'package:music_are/core/widgets/media/media_card_error.dart';
import 'package:music_are/core/widgets/media/media_card_metrics.dart';
import 'package:music_are/core/widgets/media/paginated_media_grid.dart';
import 'package:music_are/core/widgets/media/section_slot.dart';
import 'package:music_are/core/widgets/scrollable_centered.dart';
import 'package:music_are/core/widgets/settings_button.dart';
import 'package:music_are/core/widgets/skeletons/skeleton_media_grid.dart';
import 'package:music_are/features/library/presentation/cubit/library_cubit.dart';
import 'package:music_are/features/library/presentation/cubit/library_state.dart';
import 'package:music_are/features/plugin/metadata/data/services/metadata_plugin_engine.dart';
import 'package:music_are/features/plugin/metadata/presentation/cubit/metadata_plugin_cubit.dart';
import 'package:music_are/features/plugin/metadata/presentation/cubit/metadata_plugin_state.dart';
import 'package:music_are/features/plugin/metadata/presentation/utils/metadata_account_actions.dart';

class LibraryPage extends StatelessWidget {
  const LibraryPage({super.key});

  @override
  Widget build(BuildContext context) {
    // Read here, not in `create`: reading MediaQuery from a provider's create
    // callback is an invalid listening lifecycle.
    final columns = MediaCardMetrics.gridColumns(
      MediaQuery.sizeOf(context).width,
    );
    return BlocProvider<LibraryCubit>(
      create: (context) =>
          LibraryCubit(sl<MetadataPluginEngine>(), sl<NoticeBus>())
            ..updateGridColumns(columns)
            ..loadAll(),
      child: const _LibraryView(),
    );
  }
}

class _LibraryView extends StatefulWidget {
  const _LibraryView();

  @override
  State<_LibraryView> createState() => _LibraryViewState();
}

class _LibraryViewState extends State<_LibraryView>
    with SingleTickerProviderStateMixin {
  late final TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _signIn(BuildContext context) async {
    final signedIn = await MetadataAccountActions.signIn(context);
    if (signedIn && context.mounted) {
      await context.read<LibraryCubit>().loadAll();
    }
  }

  @override
  Widget build(BuildContext context) {
    return BlocListener<MetadataPluginCubit, MetadataPluginState>(
      listenWhen: (previous, next) =>
          previous.isAuthenticated != next.isAuthenticated,
      listener: (context, state) => context.read<LibraryCubit>().loadAll(),
      child: BlocBuilder<MetadataPluginCubit, MetadataPluginState>(
        builder: (context, pluginState) {
          final pluginReady = pluginState is MetadataPluginLoadedState;
          return Scaffold(
            appBar: AppBar(
              leading: IconButton(
                tooltip: context.l10n.downloads,
                icon: const Icon(Icons.download_rounded),
                onPressed: () => AppNavigator.toDownloads(context),
              ),
              title: Text(context.l10n.libraryTab),
              actions: const [SettingsButton()],
            ),
            body: !pluginReady
                ? const SizedBox.shrink()
                : BlocBuilder<LibraryCubit, LibraryState>(
                    builder: (context, state) {
                      if (!state.isAuthenticated) {
                        return ScrollableCentered(
                          child: InfoCard(
                            icon: Icons.library_music_outlined,
                            title: context.l10n.librarySignInTitle,
                            message: context.l10n.librarySignInMessage,
                            onAction: () => _signIn(context),
                            actionLabel: context.l10n.accountSignIn,
                            actionIcon: Icons.login_rounded,
                          ),
                        );
                      }

                      return LayoutBuilder(
                        builder: (context, constraints) {
                          WidgetsBinding.instance.addPostFrameCallback((_) {
                            if (!context.mounted) return;
                            context.read<LibraryCubit>().updateGridColumns(
                              MediaCardMetrics.gridColumns(constraints.maxWidth),
                            );
                          });
                          return Column(
                            children: [
                              TabBar(
                                controller: _tabController,
                                tabs: [
                                  Tab(text: context.l10n.libraryPlaylistsTab),
                                  Tab(text: context.l10n.libraryAlbumsTab),
                                  Tab(text: context.l10n.libraryArtistsTab),
                                ],
                              ),
                              Expanded(
                                child: TabBarView(
                                  controller: _tabController,
                                  children: [
                                    _PlaylistsTab(state: state),
                                    _AlbumsTab(state: state),
                                    _ArtistsTab(state: state),
                                  ],
                                ),
                              ),
                            ],
                          );
                        },
                      );
                    },
                  ),
          );
        },
      ),
    );
  }
}

class _PlaylistsTab extends StatelessWidget {
  final LibraryState state;

  const _PlaylistsTab({required this.state});

  @override
  Widget build(BuildContext context) {
    final section = state.playlists;
    final items = section.data.items;
    // *Liked Songs* is provider feedback, not a real playlist, and it has no
    // artwork: rather than a differently-shaped row it shares the grid as a
    // special first cell, so the page stays visually uniform.
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

    return PaginatedMediaGrid(
      leading: leading,
      items: items,
      hasMore: items.length < section.data.total,
      isLoadingMore: section.isLoading,
      onLoadMore: () =>
          context.read<LibraryCubit>().loadMore(LibrarySection.playlists),
      onItemTap: (item) => AppNavigator.toMediaDetail(context, item),
    );
  }
}

class _AlbumsTab extends StatelessWidget {
  final LibraryState state;

  const _AlbumsTab({required this.state});

  @override
  Widget build(BuildContext context) {
    return SectionSlot<Album>(
      section: state.albums,
      loadingBuilder: (_) => const SkeletonMediaGrid(),
      emptyTitle: context.l10n.libraryAlbumsEmpty,
      emptyMessage: context.l10n.libraryAlbumsEmptyMessage,
      emptyIcon: Icons.album_rounded,
      onRetry: () => context.read<LibraryCubit>().loadAll(),
      contentBuilder: (context, result) => PaginatedMediaGrid(
        items: result.items,
        hasMore: result.items.length < result.total,
        isLoadingMore: state.albums.isLoading,
        onLoadMore: () => context.read<LibraryCubit>().loadMore(
          LibrarySection.albums,
        ),
        onItemTap: (item) => AppNavigator.toMediaDetail(context, item),
      ),
    );
  }
}

class _ArtistsTab extends StatelessWidget {
  final LibraryState state;

  const _ArtistsTab({required this.state});

  @override
  Widget build(BuildContext context) {
    return SectionSlot<Artist>(
      section: state.artists,
      loadingBuilder: (_) => const SkeletonMediaGrid(),
      emptyTitle: context.l10n.libraryArtistsEmpty,
      emptyMessage: context.l10n.libraryArtistsEmptyMessage,
      emptyIcon: Icons.person_rounded,
      onRetry: () => context.read<LibraryCubit>().loadAll(),
      contentBuilder: (context, result) => PaginatedMediaGrid(
        items: result.items,
        hasMore: result.items.length < result.total,
        isLoadingMore: state.artists.isLoading,
        onLoadMore: () => context.read<LibraryCubit>().loadMore(
          LibrarySection.artists,
        ),
        onItemTap: (item) => AppNavigator.toMediaDetail(context, item),
      ),
    );
  }
}
