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
  final String subtitle;
  final String details;
  final List<sdk.Image> images;

  const MediaItemMetadata({
    required this.title,
    required this.mediaType,
    required this.subtitle,
    this.details = '',
    this.images = const [],
  });

  static String _cleanHtml(String text) {
    return text
        .replaceAll(RegExp(r'<[^>]*>'), '')
        .replaceAll(RegExp(r'\s+'), ' ')
        .trim();
  }

  static String _formatAlbumDetails(Album a) {
    final List<String> parts = [];
    if (a.releaseDate.trim().isNotEmpty) {
      final year = a.releaseDate.trim().split('-').first;
      if (year.isNotEmpty) parts.add(year);
    }
    if (a.totalTracks > 0) {
      parts.add('${a.totalTracks} ${a.totalTracks == 1 ? 'track' : 'tracks'}');
    }
    return parts.join(' • ');
  }

  static String _formatArtistDetails(Artist art) {
    if (art.followers != null && art.followers! > 0) {
      final count = art.followers!;
      if (count >= 1000000) {
        final m = (count / 1000000).toStringAsFixed(1).replaceAll('.0', '');
        return '$m M followers';
      } else if (count >= 1000) {
        final k = (count / 1000).toStringAsFixed(1).replaceAll('.0', '');
        return '$k K followers';
      }
      return '$count followers';
    }
    return '';
  }

  static String _formatTrackDetails(Track t) {
    final List<String> parts = [];
    if (t.album.name.trim().isNotEmpty) {
      parts.add(t.album.name.trim());
    }
    if (t.durationMs > 0) {
      final duration = Duration(milliseconds: t.durationMs);
      final min = duration.inMinutes;
      final sec = duration.inSeconds.remainder(60).toString().padLeft(2, '0');
      parts.add('$min:$sec');
    }
    return parts.join(' • ');
  }

  factory MediaItemMetadata.from(Object? item) {
    final rawItem = unboxMediaItem(item);
    return switch (rawItem) {
      Playlist p => MediaItemMetadata(
        title: p.name,
        mediaType: MediaType.playlist,
        subtitle: p.owner.name,
        details: _cleanHtml(p.description),
        images: p.images,
      ),
      Album a => MediaItemMetadata(
        title: a.name,
        mediaType: switch (a.albumType) {
          AlbumType.single => MediaType.single,
          AlbumType.compilation => MediaType.compilation,
          AlbumType.album => MediaType.album,
        },
        subtitle: a.artists.map((art) => art.name).join(', '),
        details: _formatAlbumDetails(a),
        images: a.images,
      ),
      Track t => MediaItemMetadata(
        title: t.name,
        mediaType: MediaType.track,
        subtitle: t.artists.map((art) => art.name).join(', '),
        details: _formatTrackDetails(t),
        images: t.album.images,
      ),
      Artist art => MediaItemMetadata(
        title: art.name,
        mediaType: MediaType.artist,
        subtitle: art.genres?.firstOrNull ?? '',
        details: _formatArtistDetails(art),
        images: art.images,
      ),
      _ => const MediaItemMetadata(
        title: '',
        mediaType: MediaType.unknown,
        subtitle: '',
        details: '',
      ),
    };
  }

  String getFormattedTitle(BuildContext context) {
    return title.trim().isNotEmpty ? title : context.l10n.unknownTitle;
  }

  String getFormattedSubtitle(BuildContext context) {
    final typeLabel = mediaType.toLocalizedString(context);
    final List<String> parts = [];
    if (typeLabel.isNotEmpty) parts.add(typeLabel);
    if (subtitle.isNotEmpty) parts.add(subtitle);
    return parts.join(' • ');
  }

  String getFormattedDetails(BuildContext context) {
    return details.trim();
  }
}
