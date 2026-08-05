import 'package:flutter/material.dart';

enum MediaType { playlist, album, single, compilation, track, artist, unknown }

extension MediaTypeIconExtension on MediaType {
  IconData get defaultIcon {
    return switch (this) {
      MediaType.playlist => Icons.playlist_play_rounded,
      MediaType.album ||
      MediaType.single ||
      MediaType.compilation => Icons.album_rounded,
      MediaType.artist => Icons.person_rounded,
      MediaType.track => Icons.music_note_rounded,
      MediaType.unknown => Icons.music_note_rounded,
    };
  }
}
