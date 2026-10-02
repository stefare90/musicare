import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:musicare_metadata_host_sdk/musicare_metadata_host_sdk.dart';
import 'package:music_are/core/di/injection.dart';
import 'package:music_are/core/l10n/l10n_extension.dart';
import 'package:music_are/core/notice/notice_bus.dart';
import 'package:music_are/core/router/app_navigator.dart';
import 'package:music_are/core/widgets/info_card.dart';
import 'package:music_are/core/widgets/media/media_card_metrics.dart';
import 'package:music_are/core/widgets/scrollable_centered.dart';
import 'package:music_are/core/widgets/settings_button.dart';
import 'package:music_are/features/library/presentation/cubit/library_cubit.dart';
import 'package:music_are/features/library/presentation/cubit/library_state.dart';
import 'package:music_are/features/library/presentation/widgets/create_playlist_dialog.dart';
import 'package:music_are/features/library/presentation/widgets/library_albums_tab.dart';
import 'package:music_are/features/library/presentation/widgets/library_artists_tab.dart';
import 'package:music_are/features/library/presentation/widgets/library_playlists_tab.dart';
import 'package:music_are/features/plugin/metadata/data/repositories/library_repository.dart';
import 'package:music_are/features/plugin/metadata/data/repositories/playlist_repository.dart';
import 'package:music_are/features/plugin/metadata/presentation/cubit/account_cubit.dart';
import 'package:music_are/features/plugin/metadata/presentation/cubit/account_state.dart';
import 'package:music_are/features/plugin/metadata/presentation/cubit/metadata_plugin_cubit.dart';
import 'package:music_are/features/plugin/metadata/presentation/cubit/metadata_plugin_state.dart';
import 'package:music_are/features/plugin/metadata/presentation/cubit/saved_media_cubit.dart';
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
          LibraryCubit(
            sl<LibraryRepository>(),
            sl<NoticeBus>(),
            playlist: sl<PlaylistRepository>(),
            session: sl<AccountCubit>(),
            savedMediaChanges: sl<SavedMediaCubit>().changes,
          )
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
  int _tabIndex = 0;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _tabController.addListener(_onTabChanged);
  }

  void _onTabChanged() {
    if (_tabController.index == _tabIndex) return;
    setState(() => _tabIndex = _tabController.index);
  }

  @override
  void dispose() {
    _tabController.removeListener(_onTabChanged);
    _tabController.dispose();
    super.dispose();
  }

  // The reload after signing in is driven by `AccountCubit` inside LibraryCubit.
  Future<void> _signIn(BuildContext context) async {
    await MetadataAccountActions.signIn(context);
  }

  Future<void> _createPlaylist(BuildContext context) async {
    final result = await CreatePlaylistDialog.show(context);
    if (result == null || !context.mounted) return;

    final l10n = context.l10n;
    final messenger = ScaffoldMessenger.of(context);
    final created = await context.read<LibraryCubit>().createPlaylist(
      name: result.name,
      description: result.description,
      isPublic: result.isPublic,
    );
    if (created == null || !context.mounted) return;

    // Re-read the saved index: the new playlist exists, so the change stream
    // fires and LibraryCubit reloads the Playlists tab on its own.
    await sl<SavedMediaCubit>().refresh(MediaItemType.playlist);
    messenger.showSnackBar(
      SnackBar(
        content: Text(l10n.playlistCreated),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<MetadataPluginCubit, MetadataPluginState>(
      builder: (context, pluginState) {
        final pluginReady = pluginState is MetadataPluginLoadedState;
        return BlocBuilder<AccountCubit, AccountState>(
          builder: (context, auth) {
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
              floatingActionButton:
                  pluginReady && auth.isAuthenticated && _tabIndex == 0
                  ? FloatingActionButton.extended(
                      onPressed: () => _createPlaylist(context),
                      icon: const Icon(Icons.playlist_add_rounded),
                      label: Text(context.l10n.newPlaylist),
                    )
                  : null,
              body: !pluginReady
                  ? const SizedBox.shrink()
                  : !auth.isAuthenticated
                  ? ScrollableCentered(
                      child: InfoCard(
                        icon: Icons.library_music_outlined,
                        title: context.l10n.librarySignInTitle,
                        message: context.l10n.librarySignInMessage,
                        onAction: () => _signIn(context),
                        actionLabel: context.l10n.accountSignIn,
                        actionIcon: Icons.login_rounded,
                      ),
                    )
                  : BlocBuilder<LibraryCubit, LibraryState>(
                      builder: (context, state) {
                        return LayoutBuilder(
                          builder: (context, constraints) {
                            WidgetsBinding.instance.addPostFrameCallback((_) {
                              if (!context.mounted) return;
                              context.read<LibraryCubit>().updateGridColumns(
                                MediaCardMetrics.gridColumns(
                                  constraints.maxWidth,
                                ),
                              );
                            });
                            return Column(
                              children: [
                                TabBar(
                                  controller: _tabController,
                                  tabs: [
                                    Tab(
                                      text: context.l10n.libraryPlaylistsTab,
                                    ),
                                    Tab(
                                      text: context.l10n.libraryAlbumsTab,
                                    ),
                                    Tab(
                                      text: context.l10n.libraryArtistsTab,
                                    ),
                                  ],
                                ),
                                Expanded(
                                  child: TabBarView(
                                    controller: _tabController,
                                    children: [
                                      LibraryPlaylistsTab(
                                        section: state.playlists,
                                      ),
                                      LibraryAlbumsTab(section: state.albums),
                                      LibraryArtistsTab(section: state.artists),
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
        );
      },
    );
  }
}
