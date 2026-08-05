import 'package:flutter/material.dart';
import 'package:gyawun_metadata_sdk/metadata/models/track.dart';
import 'package:music_are/core/router/app_navigator.dart';
import 'package:music_are/core/widgets/bottom_sheets/media_options_bottom_sheet.dart';

abstract class TrackOptionsBottomSheet {
  static Future<void> show(
    BuildContext context,
    Track track, {
    VoidCallback? onAddToQueue,
    VoidCallback? onToggleFavorite,
  }) {
    return MediaOptionsBottomSheet.show(
      context: context,
      item: track,
      options: [
        ListTile(
          leading: const Icon(Icons.playlist_add_rounded),
          title: const Text('Add to Queue'),
          onTap: () {
            Navigator.of(context).pop();
            onAddToQueue?.call();
          },
        ),
        ListTile(
          leading: const Icon(Icons.favorite_border_rounded),
          title: const Text('Save to Favorites'),
          onTap: () {
            Navigator.of(context).pop();
            onToggleFavorite?.call();
          },
        ),
        if (track.album.id.isNotEmpty)
          ListTile(
            leading: const Icon(Icons.album_rounded),
            title: const Text('Go to Album'),
            onTap: () {
              Navigator.of(context).pop();
              AppNavigator.toAlbumDetail(context, track.album);
            },
          ),
        if (track.artists.isNotEmpty)
          ListTile(
            leading: const Icon(Icons.person_rounded),
            title: const Text('Go to Artist'),
            onTap: () {
              Navigator.of(context).pop();
              AppNavigator.toArtistDetail(context, track.artists.first);
            },
          ),
      ],
    );
  }
}
