import 'package:flutter/material.dart';
import 'package:gyawun_metadata_sdk/metadata/models/track.dart';
import 'package:music_are/core/l10n/l10n_extension.dart';
import 'package:music_are/core/router/app_navigator.dart';
import 'package:music_are/core/widgets/bottom_sheets/media_options_bottom_sheet.dart';

abstract class TrackOptionsBottomSheet {
  static Future<void> show(
    BuildContext context,
    Track track, {
    VoidCallback? onAddToQueue,
    VoidCallback? onToggleFavorite,
  }) {
    final l10n = context.l10n;
    return MediaOptionsBottomSheet.show(
      context: context,
      item: track,
      options: [
        ListTile(
          leading: const Icon(Icons.playlist_add_rounded),
          title: Text(l10n.addToQueue),
          onTap: () {
            Navigator.of(context).pop();
            onAddToQueue?.call();
          },
        ),
        ListTile(
          leading: const Icon(Icons.favorite_border_rounded),
          title: Text(l10n.saveToFavorites),
          onTap: () {
            Navigator.of(context).pop();
            onToggleFavorite?.call();
          },
        ),
        if (track.album.id.isNotEmpty)
          ListTile(
            leading: const Icon(Icons.album_rounded),
            title: Text(l10n.goToAlbum),
            onTap: () {
              Navigator.of(context).pop();
              AppNavigator.toAlbumDetail(context, track.album);
            },
          ),
        if (track.artists.isNotEmpty)
          ListTile(
            leading: const Icon(Icons.person_rounded),
            title: Text(l10n.goToArtist),
            onTap: () {
              Navigator.of(context).pop();
              AppNavigator.toArtistDetail(context, track.artists.first);
            },
          ),
      ],
    );
  }
}
