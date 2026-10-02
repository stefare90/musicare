import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:musicare_metadata_host_sdk/musicare_metadata_host_sdk.dart';
import 'package:music_are/core/di/injection.dart';
import 'package:music_are/core/l10n/l10n_extension.dart';
import 'package:music_are/core/models/media_type.dart';
import 'package:music_are/core/notice/notice_bus.dart';
import 'package:music_are/core/theme/theme_extension.dart';
import 'package:music_are/core/widgets/bottom_sheets/base_modal_bottom_sheet.dart';
import 'package:music_are/core/widgets/error_card.dart';
import 'package:music_are/core/widgets/info_card.dart';
import 'package:music_are/core/widgets/media/media_cover_image.dart';
import 'package:music_are/core/widgets/scrollable_centered.dart';
import 'package:music_are/features/library/presentation/cubit/add_to_playlist_cubit.dart';
import 'package:music_are/features/library/presentation/cubit/add_to_playlist_state.dart';
import 'package:music_are/features/library/presentation/widgets/create_playlist_dialog.dart';
import 'package:music_are/features/plugin/metadata/data/repositories/library_repository.dart';
import 'package:music_are/features/plugin/metadata/data/repositories/playlist_repository.dart';
import 'package:music_are/features/plugin/metadata/presentation/cubit/account_cubit.dart';
import 'package:music_are/features/plugin/metadata/presentation/utils/metadata_account_actions.dart';

/// Picker for "Add to playlist": the user's playlists plus a "New playlist"
/// entry that creates one and adds the track in a single flow.
class AddToPlaylistBottomSheet extends StatelessWidget {
  final Track track;

  const AddToPlaylistBottomSheet({super.key, required this.track});

  static Future<void> show(BuildContext context, Track track) {
    return BaseModalBottomSheet.show(
      context: context,
      child: AddToPlaylistBottomSheet(track: track),
    );
  }

  @override
  Widget build(BuildContext context) {
    return BlocProvider<AddToPlaylistCubit>(
      create: (context) =>
          AddToPlaylistCubit(
            sl<LibraryRepository>(),
            sl<PlaylistRepository>(),
            sl<NoticeBus>(),
            auth: sl<AccountCubit>(),
          )..load(),
      child: _AddToPlaylistBody(track: track),
    );
  }
}

class _AddToPlaylistBody extends StatelessWidget {
  final Track track;

  const _AddToPlaylistBody({required this.track});

  Future<void> _createPlaylist(BuildContext context) async {
    final result = await CreatePlaylistDialog.show(context);
    if (result == null || !context.mounted) return;

    final l10n = context.l10n;
    final messenger = ScaffoldMessenger.of(context);
    final created = await context.read<AddToPlaylistCubit>().createPlaylist(
      name: result.name,
      description: result.description,
      isPublic: result.isPublic,
      trackIds: [track.id],
    );
    if (created == null || !context.mounted) return;

    Navigator.of(context).pop();
    messenger.showSnackBar(
      SnackBar(
        content: Text(l10n.playlistCreated),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  Future<void> _addToPlaylist(BuildContext context, Playlist playlist) async {
    final l10n = context.l10n;
    final messenger = ScaffoldMessenger.of(context);
    final added = await context.read<AddToPlaylistCubit>().addTrack(
      playlist,
      track,
    );
    if (!added || !context.mounted) return;

    Navigator.of(context).pop();
    messenger.showSnackBar(
      SnackBar(
        content: Text(l10n.addedToPlaylist(playlist.name)),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return BaseModalBottomSheet(
      title: context.l10n.addToPlaylist,
      icon: Icons.playlist_add_rounded,
      initialChildSize: 0.5,
      minChildSize: 0.3,
      maxChildSize: 0.8,
      builder: (context, scrollController) {
        return BlocBuilder<AddToPlaylistCubit, AddToPlaylistState>(
          builder: (context, state) {
            final section = state.playlists;
            if (section.error is MetadataAuthRequiredException) {
              return ScrollableCentered(
                child: InfoCard(
                  icon: Icons.login_rounded,
                  title: context.l10n.playlistsSignInTitle,
                  onAction: () => MetadataAccountActions.signIn(context),
                  actionLabel: context.l10n.accountSignIn,
                  actionIcon: Icons.login_rounded,
                ),
              );
            }
            if (section.error != null && section.data.items.isEmpty) {
              return ScrollableCentered(
                child: ErrorCard(
                  error: section.error!,
                  onRetry: () => context.read<AddToPlaylistCubit>().load(),
                ),
              );
            }
            if (section.isLoading && section.data.items.isEmpty) {
              return const Center(
                child: Padding(
                  padding: EdgeInsets.all(24.0),
                  child: CircularProgressIndicator(),
                ),
              );
            }

            final playlists = section.data.items;
            final hasMore = playlists.length < section.data.total;
            final showProgress = section.isLoading && playlists.isNotEmpty;

            return NotificationListener<ScrollNotification>(
              onNotification: (info) {
                if (hasMore &&
                    !section.isLoading &&
                    info.metrics.extentAfter < 200) {
                  context.read<AddToPlaylistCubit>().loadMore();
                }
                return false;
              },
              child: ListView.builder(
                controller: scrollController,
                padding: const EdgeInsets.symmetric(vertical: 8.0),
                itemCount:
                    1 + (playlists.isEmpty ? 1 : playlists.length) +
                    (showProgress ? 1 : 0),
                itemBuilder: (context, index) {
                  if (index == 0) {
                    return ListTile(
                      leading: Container(
                        width: 48,
                        height: 48,
                        decoration: BoxDecoration(
                          color: context.colorScheme.primary.withValues(
                            alpha: 0.15,
                          ),
                          borderRadius: BorderRadius.circular(8.0),
                        ),
                        child: Icon(
                          Icons.add_rounded,
                          color: context.colorScheme.primary,
                        ),
                      ),
                      title: Text(
                        context.l10n.newPlaylist,
                        style: context.textTheme.titleMedium,
                      ),
                      onTap: () => _createPlaylist(context),
                    );
                  }
                  if (playlists.isEmpty) {
                    return Padding(
                      padding: const EdgeInsets.fromLTRB(16.0, 12.0, 16.0, 0.0),
                      child: Text(
                        context.l10n.noPlaylistsYetMessage,
                        style: context.textTheme.bodyMedium?.copyWith(
                          color: context.colorScheme.onSurfaceVariant,
                        ),
                      ),
                    );
                  }
                  if (index > playlists.length) {
                    return const Center(
                      child: Padding(
                        padding: EdgeInsets.all(16.0),
                        child: CircularProgressIndicator(),
                      ),
                    );
                  }
                  final playlist = playlists[index - 1];
                  return ListTile(
                    leading: MediaCoverImage(
                      images: playlist.images,
                      mediaType: MediaType.playlist,
                      width: 48,
                      height: 48,
                      borderRadius: BorderRadius.circular(8.0),
                    ),
                    title: Text(
                      playlist.name,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: context.textTheme.titleMedium,
                    ),
                    subtitle: playlist.description.isNotEmpty
                        ? Text(
                            playlist.description,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          )
                        : null,
                    onTap: state.isMutating
                        ? null
                        : () => _addToPlaylist(context, playlist),
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
