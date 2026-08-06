import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:gyawun_metadata_sdk/metadata/models/playlist.dart';
import 'package:music_are/core/di/injection.dart';
import 'package:music_are/core/models/media_type.dart';
import 'package:music_are/core/widgets/bottom_sheets/bottom_sheets.dart';
import 'package:music_are/core/widgets/dialogs.dart';
import 'package:music_are/core/widgets/error_card.dart';
import 'package:music_are/core/widgets/media/sliver_media_app_bar.dart';
import 'package:music_are/core/widgets/media/sliver_media_header.dart';
import 'package:music_are/core/widgets/media/sliver_track_list.dart';
import 'package:music_are/features/details/playlist/presentation/cubit/playlist_cubit.dart';
import 'package:music_are/features/details/playlist/presentation/cubit/playlist_state.dart';
import 'package:music_are/features/plugin/data/services/plugin_engine.dart';
import 'package:music_are/features/plugin/presentation/utils/exception_localizer.dart';

class PlaylistPage extends StatelessWidget {
  final Playlist playlist;

  const PlaylistPage({super.key, required this.playlist});

  @override
  Widget build(BuildContext context) {
    return BlocProvider<PlaylistCubit>(
      create: (context) =>
          PlaylistCubit(sl<PluginEngine>())..loadPlaylist(playlist),
      child: const _PlaylistView(),
    );
  }
}

class _PlaylistView extends StatefulWidget {
  const _PlaylistView();

  @override
  State<_PlaylistView> createState() => _PlaylistViewState();
}

class _PlaylistViewState extends State<_PlaylistView> {
  final GlobalKey _largeTitleKey = GlobalKey();
  final ValueNotifier<bool> _isScrolledPast = ValueNotifier<bool>(false);

  @override
  void dispose() {
    _isScrolledPast.dispose();
    super.dispose();
  }

  void _checkTitlePosition(BuildContext context) {
    final renderBox =
        _largeTitleKey.currentContext?.findRenderObject() as RenderBox?;
    if (renderBox != null && renderBox.hasSize) {
      final position = renderBox.localToGlobal(Offset.zero);
      final topPadding = MediaQuery.of(context).padding.top;
      final appBarBottom = topPadding + kToolbarHeight;
      final largeTitleBottomY = position.dy + renderBox.size.height;
      final isPast = largeTitleBottomY <= appBarBottom;
      if (isPast != _isScrolledPast.value) {
        _isScrolledPast.value = isPast;
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: BlocConsumer<PlaylistCubit, PlaylistState>(
        listenWhen: (prev, curr) =>
            curr is PlaylistLoadedState && curr.refreshError != null,
        listener: (context, state) {
          if (state is PlaylistLoadedState && state.refreshError != null) {
            Dialogs.showErrorSnackBar(
              context,
              message: state.refreshError!.toLocalizedString(context),
            );
          }
        },
        builder: (context, state) {
          final metadata = state.metadata;

          return NotificationListener<ScrollNotification>(
            onNotification: (notification) {
              _checkTitlePosition(context);
              return false;
            },
            child: CustomScrollView(
              physics: const AlwaysScrollableScrollPhysics(),
              slivers: [
                if (metadata != null)
                  SliverMediaAppBar(
                    title: metadata.title,
                    isSaved: state is PlaylistLoadedState && state.isSaved,
                    isScrolledPast: _isScrolledPast,
                    onSaveTap: state is PlaylistLoadedState
                        ? () => context.read<PlaylistCubit>().toggleSave()
                        : null,
                    onOptionsTap: state is PlaylistLoadedState
                        ? () => PlaylistOptionsBottomSheet.show(
                            context,
                            state.playlist,
                            onToggleSave: () =>
                                context.read<PlaylistCubit>().toggleSave(),
                          )
                        : null,
                  ),
                if (metadata != null)
                  SliverMediaHeader(meta: metadata, titleKey: _largeTitleKey),
                if (state is PlaylistErrorState)
                  SliverFillRemaining(
                    child: Center(
                      child: ErrorCard(
                        error: state.error,
                        onRetry: () => context
                            .read<PlaylistCubit>()
                            .loadPlaylist(state.playlist),
                      ),
                    ),
                  )
                else if (state is PlaylistLoadedState)
                  SliverTrackList(
                    tracks: state.tracks.items,
                    listType: MediaType.playlist,
                    hasMore: state.hasMoreTracks,
                    onLoadMore: () =>
                        context.read<PlaylistCubit>().loadMoreTracks(),
                    onTrackTap: (track) {
                      // TODO: Phase 10 - Trigger Playback in AudioPlayerCubit
                    },
                    onTrackOptionsTap: (track) {
                      TrackOptionsBottomSheet.show(context, track);
                    },
                  )
                else
                  const SliverFillRemaining(
                    child: Center(child: CircularProgressIndicator()),
                  ),
              ],
            ),
          );
        },
      ),
    );
  }
}
