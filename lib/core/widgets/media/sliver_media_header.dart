import 'package:flutter/material.dart';
import 'package:music_are/core/models/media_item_metadata.dart';
import 'package:music_are/core/models/media_type.dart';
import 'package:music_are/core/widgets/media/artist_media_header.dart';
import 'package:music_are/core/widgets/media/collection_media_header.dart';
import 'package:music_are/core/widgets/media/media_header_text.dart';

class SliverMediaHeader extends StatelessWidget {
  final MediaItemMetadata meta;
  final Key? titleKey;

  final Widget? badge;

  const SliverMediaHeader({
    super.key,
    required this.meta,
    this.titleKey,
    this.badge,
  });

  @override
  Widget build(BuildContext context) {
    final text = MediaHeaderText(meta: meta, titleKey: titleKey, badge: badge);

    return meta.mediaType == MediaType.artist
        ? ArtistMediaHeader(meta: meta, child: text)
        : CollectionMediaHeader(meta: meta, child: text);
  }
}
