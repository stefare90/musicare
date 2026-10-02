import 'package:flutter/material.dart';
import 'package:musicare_metadata_host_sdk/musicare_metadata_host_sdk.dart';
import 'package:music_are/core/l10n/l10n_extension.dart';
import 'package:music_are/core/router/app_navigator.dart';
import 'package:music_are/core/widgets/bottom_sheets/media_options_bottom_sheet.dart';

abstract class AlbumOptionsBottomSheet {
  static Future<void> show(
    BuildContext context,
    Album album, {
    bool isSaved = false,
    VoidCallback? onToggleSave,
    VoidCallback? onShare,
  }) {
    final l10n = context.l10n;
    return MediaOptionsBottomSheet.show(
      context: context,
      item: album,
      options: [
        ListTile(
          leading: Icon(
            isSaved ? Icons.favorite_rounded : Icons.favorite_border_rounded,
          ),
          title: Text(isSaved ? l10n.removeAlbum : l10n.saveAlbum),
          onTap: () {
            Navigator.of(context).pop();
            onToggleSave?.call();
          },
        ),
        if (album.artists.isNotEmpty)
          ListTile(
            leading: const Icon(Icons.person_rounded),
            title: Text(l10n.goToArtist),
            onTap: () {
              Navigator.of(context).pop();
              AppNavigator.toArtistDetail(context, album.artists.first);
            },
          ),
        ListTile(
          leading: const Icon(Icons.share_rounded),
          title: Text(l10n.shareAlbum),
          onTap: () {
            Navigator.of(context).pop();
            onShare?.call();
          },
        ),
      ],
    );
  }
}
