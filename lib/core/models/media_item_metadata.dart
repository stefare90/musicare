import 'package:dart_eval/dart_eval_bridge.dart';
import 'package:flutter/material.dart';
import 'package:gyawun_metadata_sdk/metadata/models/album.dart';
import 'package:gyawun_metadata_sdk/metadata/models/artist.dart';
import 'package:gyawun_metadata_sdk/metadata/models/playlist.dart';
import 'package:gyawun_metadata_sdk/metadata/models/track.dart';
import 'package:music_are/core/models/media_type.dart';
import 'package:music_are/core/utils/media_type_localizer.dart';

class MediaItemMetadata {
  final String title;
  final MediaType mediaType;
  final String subtitleDetail;
  final String? imageUrl;
  final IconData fallbackIcon;

  const MediaItemMetadata({
    required this.title,
    required this.mediaType,
    required this.subtitleDetail,
    this.imageUrl,
    required this.fallbackIcon,
  });

  factory MediaItemMetadata.from(dynamic item) {
    final rawItem = (item is $Value) ? item.$value : item;
    return switch (rawItem) {
      Playlist p => MediaItemMetadata(
        title: p.name,
        mediaType: MediaType.playlist,
        subtitleDetail: p.owner.name,
        imageUrl: p.images.firstOrNull?.url,
        fallbackIcon: Icons.playlist_play_rounded,
      ),
      Album a => MediaItemMetadata(
        title: a.name,
        mediaType: switch (a.albumType) {
          AlbumType.single => MediaType.single,
          AlbumType.compilation => MediaType.compilation,
          AlbumType.album => MediaType.album,
        },
        subtitleDetail: a.artists.map((art) => art.name).join(', '),
        imageUrl: a.images.firstOrNull?.url,
        fallbackIcon: Icons.album_rounded,
      ),
      Track t => MediaItemMetadata(
        title: t.name,
        mediaType: MediaType.track,
        subtitleDetail: t.artists.map((art) => art.name).join(', '),
        imageUrl: t.album.images.firstOrNull?.url,
        fallbackIcon: Icons.music_note_rounded,
      ),
      Artist art => MediaItemMetadata(
        title: art.name,
        mediaType: MediaType.artist,
        subtitleDetail: art.genres?.firstOrNull ?? '',
        imageUrl: art.images.firstOrNull?.url,
        fallbackIcon: Icons.person_rounded,
      ),
      _ => const MediaItemMetadata(
        title: 'Unknown',
        mediaType: MediaType.unknown,
        subtitleDetail: '',
        fallbackIcon: Icons.music_note_rounded,
      ),
    };
  }

  String toFormattedSubtitle(BuildContext context) {
    final typeLabel = mediaType.toLocalizedString(context);
    final List<String> parts = [];
    if (typeLabel.isNotEmpty) parts.add(typeLabel);
    if (subtitleDetail.isNotEmpty) parts.add(subtitleDetail);
    return parts.join(' • ');
  }
}
