import 'package:flutter/material.dart';
import 'package:music_are/core/l10n/l10n_extension.dart';
import 'package:music_are/core/models/media_type.dart';

extension MediaTypeLocalizer on MediaType {
  String toLocalizedString(BuildContext context) {
    final l10n = context.l10n;
    return switch (this) {
      MediaType.playlist => l10n.mediaTypePlaylist,
      MediaType.album => l10n.mediaTypeAlbum,
      MediaType.single => l10n.mediaTypeSingle,
      MediaType.compilation => l10n.mediaTypeCompilation,
      MediaType.track => l10n.mediaTypeTrack,
      MediaType.artist => l10n.mediaTypeArtist,
      MediaType.unknown => l10n.mediaTypeUnknown,
    };
  }
}
