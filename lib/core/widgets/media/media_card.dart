import 'package:flutter/material.dart';
import 'package:music_are/core/models/media_item_metadata.dart';
import 'package:music_are/core/theme/theme_extension.dart';
import 'package:music_are/core/widgets/media/media_cover_image.dart';

class MediaCard extends StatelessWidget {
  final Object item;
  final VoidCallback? onTap;
  final double width;

  const MediaCard({
    super.key,
    required this.item,
    this.onTap,
    this.width = 150.0,
  });

  @override
  Widget build(BuildContext context) {
    final meta = MediaItemMetadata.from(item);
    final subtitle = meta.getFormattedSubtitle(context);

    return Container(
      width: width,
      margin: const EdgeInsets.symmetric(horizontal: 4.0),
      child: Card(
        clipBehavior: Clip.antiAlias,
        elevation: 1,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(14.0),
        ),
        child: InkWell(
          onTap: onTap,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              AspectRatio(
                aspectRatio: 1.0,
                child: MediaCoverImage(
                  images: meta.images,
                  mediaType: meta.mediaType,
                ),
              ),
              Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 8.0,
                  vertical: 6.0,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      meta.title,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: context.textTheme.titleMedium?.copyWith(
                        fontSize: 12.5,
                        fontWeight: FontWeight.bold,
                        color: context.colorScheme.primary,
                        height: 1.15,
                      ),
                    ),
                    const SizedBox(height: 2),
                    if (subtitle.isNotEmpty)
                      Text(
                        subtitle,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: context.textTheme.labelSmall?.copyWith(
                          fontSize: 10.5,
                          color: context.colorScheme.onSurfaceVariant,
                        ),
                      ),
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
