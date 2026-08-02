import 'package:flutter/material.dart';
import 'package:gyawun_metadata_sdk/metadata/models/album.dart';
import 'package:gyawun_metadata_sdk/metadata/models/playlist.dart';
import 'package:gyawun_metadata_sdk/metadata/models/track.dart';
import 'package:music_are/core/theme/theme_extension.dart';

class SectionItemCard extends StatelessWidget {
  final dynamic item;
  final VoidCallback? onTap;
  final double width;

  const SectionItemCard({
    super.key,
    required this.item,
    this.onTap,
    this.width = 135.0,
  });

  @override
  Widget build(BuildContext context) {
    String title = 'Unknown';
    String subtitle = '';
    String? imageUrl;

    if (item is Playlist) {
      final playlist = item as Playlist;
      title = playlist.name;
      subtitle = playlist.description;
      if (playlist.images.isNotEmpty) imageUrl = playlist.images.first.url;
    } else if (item is Album) {
      final album = item as Album;
      title = album.name;
      subtitle = album.artists.map((a) => a.name).join(', ');
      if (album.images.isNotEmpty) imageUrl = album.images.first.url;
    } else if (item is Track) {
      final track = item as Track;
      title = track.name;
      subtitle = track.artists.map((a) => a.name).join(', ');
      if (track.album.images.isNotEmpty) {
        imageUrl = track.album.images.first.url;
      }
    }

    return Container(
      width: width,
      margin: const EdgeInsets.symmetric(horizontal: 4.0),
      child: Card(
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: onTap,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: imageUrl != null && imageUrl.isNotEmpty
                    ? Image.network(
                        imageUrl,
                        width: double.infinity,
                        fit: BoxFit.cover,
                        errorBuilder: (_, __, ___) => const Center(
                          child: Icon(Icons.music_note, size: 40),
                        ),
                      )
                    : Container(
                        color: Theme.of(
                          context,
                        ).colorScheme.surfaceContainerHigh,
                        child: const Center(
                          child: Icon(Icons.music_note, size: 40),
                        ),
                      ),
              ),
              Padding(
                padding: const EdgeInsets.all(8.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: context.textTheme.titleMedium?.copyWith(
                        fontSize: 13,
                      ),
                    ),
                    if (subtitle.isNotEmpty) ...[
                      const SizedBox(height: 2),
                      Text(
                        subtitle,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: context.textTheme.labelSmall,
                      ),
                    ],
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
