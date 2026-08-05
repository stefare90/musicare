import 'package:flutter/material.dart';
import 'package:music_are/core/models/media_item_metadata.dart';
import 'package:music_are/core/theme/theme_extension.dart';
import 'package:music_are/core/widgets/media/media_cover_image.dart';

class SliverMediaHeader extends StatelessWidget {
  final MediaItemMetadata meta;
  final bool isCircular;
  final Key? titleKey;

  static const double _coverSize = 160.0;

  const SliverMediaHeader({
    super.key,
    required this.meta,
    this.isCircular = false,
    this.titleKey,
  });

  @override
  Widget build(BuildContext context) {
    return SliverToBoxAdapter(
      child: Padding(
        padding: const EdgeInsets.only(
          top: 8.0,
          bottom: 24.0,
          left: 24.0,
          right: 24.0,
        ),
        child: Column(
          children: [
            MediaCoverImage(
              images: meta.images,
              mediaType: meta.mediaType,
              width: _coverSize,
              height: _coverSize,
              borderRadius: isCircular
                  ? BorderRadius.circular(_coverSize / 2)
                  : BorderRadius.circular(16.0),
            ),
            const SizedBox(height: 16),
            Text(
              meta.title,
              key: titleKey,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              textAlign: TextAlign.center,
              style: context.textTheme.headlineMedium?.copyWith(
                fontWeight: FontWeight.bold,
                color: context.colorScheme.primary,
              ),
            ),
            if (meta.subtitleDetail.isNotEmpty) ...[
              const SizedBox(height: 6),
              Text(
                meta.subtitleDetail,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                textAlign: TextAlign.center,
                style: context.textTheme.bodyMedium?.copyWith(
                  color: context.colorScheme.onSurfaceVariant,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
