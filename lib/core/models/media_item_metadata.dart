import 'package:flutter/material.dart';
import 'package:gyawun_metadata_sdk/metadata/models/album.dart';
import 'package:gyawun_metadata_sdk/metadata/models/artist.dart';
import 'package:gyawun_metadata_sdk/metadata/models/image.dart' as sdk;
import 'package:gyawun_metadata_sdk/metadata/models/playlist.dart';
import 'package:gyawun_metadata_sdk/metadata/models/track.dart';
import 'package:music_are/core/l10n/l10n_extension.dart';
import 'package:music_are/core/models/media_type.dart';
import 'package:music_are/core/utils/media_item_unboxer.dart';
import 'package:music_are/core/utils/media_type_localizer.dart';

class MediaItemMetadata {
  final String title;
  final MediaType mediaType;
  final String subtitleDetail;
  final List<sdk.Image> images;

  const MediaItemMetadata({
    required this.title,
    required this.mediaType,
    required this.subtitleDetail,
    this.images = const [],
  });

  factory MediaItemMetadata.from(Object? item) {
    final rawItem = unboxMediaItem(item);
    return switch (rawItem) {
      Playlist p => MediaItemMetadata(
        title: p.name,
        mediaType: MediaType.playlist,
        subtitleDetail: p.owner.name,
        images: p.images,
      ),
      Album a => MediaItemMetadata(
        title: a.name,
        mediaType: switch (a.albumType) {
          AlbumType.single => MediaType.single,
          AlbumType.compilation => MediaType.compilation,
          AlbumType.album => MediaType.album,
        },
        subtitleDetail: a.artists.map((art) => art.name).join(', '),
        images: a.images,
      ),
      Track t => MediaItemMetadata(
        title: t.name,
        mediaType: MediaType.track,
        subtitleDetail: t.artists.map((art) => art.name).join(', '),
        images: t.album.images,
      ),
      Artist art => MediaItemMetadata(
        title: art.name,
        mediaType: MediaType.artist,
        subtitleDetail: art.genres?.firstOrNull ?? '',
        images: art.images,
      ),
      _ => const MediaItemMetadata(
        title: '',
        mediaType: MediaType.unknown,
        subtitleDetail: '',
      ),
    };
  }

  String getDisplayTitle(BuildContext context) {
    return title.isNotEmpty ? title : context.l10n.unknownTitle;
  }

  String toFormattedSubtitle(BuildContext context) {
    final typeLabel = mediaType.toLocalizedString(context);
    final List<String> parts = [];
    if (typeLabel.isNotEmpty) parts.add(typeLabel);
    if (subtitleDetail.isNotEmpty) parts.add(subtitleDetail);
    return parts.join(' • ');
  }
}
