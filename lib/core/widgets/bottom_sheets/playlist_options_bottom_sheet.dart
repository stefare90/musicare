import 'package:flutter/material.dart';
import 'package:gyawun_metadata_sdk/metadata/models/playlist.dart';
import 'package:music_are/core/l10n/l10n_extension.dart';
import 'package:music_are/core/widgets/bottom_sheets/media_options_bottom_sheet.dart';

abstract class PlaylistOptionsBottomSheet {
  static Future<void> show(
    BuildContext context,
    Playlist playlist, {
    VoidCallback? onToggleSave,
    VoidCallback? onDelete,
    VoidCallback? onShare,
  }) {
    final l10n = context.l10n;
    return MediaOptionsBottomSheet.show(
      context: context,
      item: playlist,
      options: [
        ListTile(
          leading: const Icon(Icons.favorite_border_rounded),
          title: Text(l10n.savePlaylist),
          onTap: () {
            Navigator.of(context).pop();
            onToggleSave?.call();
          },
        ),
        ListTile(
          leading: const Icon(Icons.share_rounded),
          title: Text(l10n.sharePlaylist),
          onTap: () {
            Navigator.of(context).pop();
            onShare?.call();
          },
        ),
        if (onDelete != null)
          ListTile(
            leading: const Icon(Icons.delete_outline_rounded),
            title: Text(l10n.deletePlaylist),
            onTap: () {
              Navigator.of(context).pop();
              onDelete.call();
            },
          ),
      ],
    );
  }
}
