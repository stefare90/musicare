import 'package:flutter/material.dart';
import 'package:musicare_metadata_host_sdk/musicare_metadata_host_sdk.dart';
import 'package:music_are/core/l10n/l10n_extension.dart';
import 'package:music_are/core/router/app_navigator.dart';
import 'package:music_are/core/widgets/bottom_sheets/artist_selection_bottom_sheet.dart';
import 'package:music_are/core/widgets/bottom_sheets/media_options_bottom_sheet.dart';

abstract class TrackOptionsBottomSheet {
  static Future<void> show(
    BuildContext context,
    Track track, {
    bool isSaved = false,
    VoidCallback? onAddToQueue,
    VoidCallback? onToggleFavorite,
    VoidCallback? onAddToPlaylist,
    VoidCallback? onBeforeNavigate,
  }) {
    final l10n = context.l10n;
    return MediaOptionsBottomSheet.show(
      context: context,
      item: track,
      options: [
        ListTile(
          leading: const Icon(Icons.queue_music_rounded),
          title: Text(l10n.addToQueue),
          onTap: () {
            Navigator.of(context).pop();
            onAddToQueue?.call();
          },
        ),
        ListTile(
          leading: Icon(
            isSaved ? Icons.favorite_rounded : Icons.favorite_border_rounded,
          ),
          title: Text(
            isSaved ? l10n.removeFromFavorites : l10n.saveToFavorites,
          ),
          onTap: () {
            Navigator.of(context).pop();
            onToggleFavorite?.call();
          },
        ),
        ListTile(
          leading: const Icon(Icons.playlist_add_rounded),
          title: Text(l10n.addToPlaylist),
          onTap: () {
            Navigator.of(context).pop();
            onAddToPlaylist?.call();
          },
        ),
        if (track.album.id.isNotEmpty)
          ListTile(
            leading: const Icon(Icons.album_rounded),
            title: Text(l10n.goToAlbum),
            onTap: () {
              Navigator.of(context).pop();
              onBeforeNavigate?.call();
              AppNavigator.toAlbumDetail(context, track.album);
            },
          ),
        if (track.artists.isNotEmpty)
          ListTile(
            leading: const Icon(Icons.person_rounded),
            title: Text(l10n.goToArtist),
            onTap: () {
              Navigator.of(context).pop();
              if (track.artists.length > 1) {
                ArtistSelectionBottomSheet.show(
                  context,
                  track.artists,
                  onSelected: onBeforeNavigate,
                );
                return;
              }
              onBeforeNavigate?.call();
              AppNavigator.toArtistDetail(context, track.artists.first);
            },
          ),
      ],
    );
  }
}
