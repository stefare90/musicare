import 'package:flutter/material.dart';
import 'package:gyawun_metadata_sdk/metadata/models/album.dart';
import 'package:music_are/core/router/app_navigator.dart';
import 'package:music_are/core/widgets/bottom_sheets/media_options_bottom_sheet.dart';

abstract class AlbumOptionsBottomSheet {
  static Future<void> show(
    BuildContext context,
    Album album, {
    VoidCallback? onToggleSave,
    VoidCallback? onShare,
  }) {
    return MediaOptionsBottomSheet.show(
      context: context,
      item: album,
      options: [
        ListTile(
          leading: const Icon(Icons.favorite_border_rounded),
          title: const Text('Save Album'),
          onTap: () {
            Navigator.of(context).pop();
            onToggleSave?.call();
          },
        ),
        if (album.artists.isNotEmpty)
          ListTile(
            leading: const Icon(Icons.person_rounded),
            title: const Text('Go to Artist'),
            onTap: () {
              Navigator.of(context).pop();
              AppNavigator.toArtistDetail(context, album.artists.first);
            },
          ),
        ListTile(
          leading: const Icon(Icons.share_rounded),
          title: const Text('Share Album'),
          onTap: () {
            Navigator.of(context).pop();
            onShare?.call();
          },
        ),
      ],
    );
  }
}
