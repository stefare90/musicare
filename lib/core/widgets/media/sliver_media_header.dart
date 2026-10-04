import 'package:flutter/material.dart';
import 'package:music_are/core/models/media_item_metadata.dart';
import 'package:music_are/core/models/media_type.dart';
import 'package:music_are/core/theme/theme_extension.dart';
import 'package:music_are/core/widgets/media/media_cover_image.dart';

class SliverMediaHeader extends StatelessWidget {
  final MediaItemMetadata meta;
  final Key? titleKey;

  /// Optional element shown right below the title (e.g. playlist visibility).
  final Widget? badge;

  static const double _coverSize = 160.0;

  const SliverMediaHeader({
    super.key,
    required this.meta,
    this.titleKey,
    this.badge,
  });

  @override
  Widget build(BuildContext context) {
    final formattedTitle = meta.getFormattedTitle(context);
    final formattedDetails = meta.getFormattedDetails(context);
    final bool isCircular = meta.mediaType == MediaType.artist;

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
              formattedTitle,
              key: titleKey,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              textAlign: TextAlign.center,
              style: context.textTheme.headlineSmall?.copyWith(
                color: context.colorScheme.primary,
              ),
            ),
            if (badge != null) ...[
              const SizedBox(height: 8),
              badge!,
            ],
            if (meta.subtitle.isNotEmpty) ...[
              const SizedBox(height: 6),
              Text(
                meta.subtitle,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                textAlign: TextAlign.center,
                style: context.textTheme.titleSmall?.copyWith(
                  color: context.colorScheme.onSurfaceVariant,
                ),
              ),
            ],
            if (formattedDetails.isNotEmpty) ...[
              const SizedBox(height: 8),
              Text(
                formattedDetails,
                maxLines: 4,
                overflow: TextOverflow.ellipsis,
                textAlign: TextAlign.center,
                style: context.textTheme.bodySmall?.copyWith(
                  color: context.colorScheme.onSurfaceVariant.withValues(
                    alpha: 0.5,
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
