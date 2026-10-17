import 'package:flutter/material.dart';
import 'package:music_are/core/models/media_item_metadata.dart';
import 'package:music_are/core/theme/theme_extension.dart';

/// Title, badge, subtitle and details shared by the artist and collection
/// headers.
class MediaHeaderText extends StatelessWidget {
  final MediaItemMetadata meta;
  final Key? titleKey;
  final Widget? badge;

  const MediaHeaderText({
    super.key,
    required this.meta,
    this.titleKey,
    this.badge,
  });

  @override
  Widget build(BuildContext context) {
    final formattedTitle = meta.getFormattedTitle(context);
    final formattedDetails = meta.getFormattedDetails(context);

    // Full width so the nested column does not shrink-wrap to its widest
    // child (which would re-wrap the title).
    return SizedBox(
      width: double.infinity,
      child: Column(
        children: [
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
          if (badge != null) ...[const SizedBox(height: 8), badge!],
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
    );
  }
}
