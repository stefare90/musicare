import 'package:flutter/material.dart';
import 'package:music_are/core/models/media_item_metadata.dart';
import 'package:music_are/core/theme/theme_extension.dart';
import 'package:music_are/core/widgets/media/media_card_metrics.dart';
import 'package:music_are/core/widgets/media/media_cover_image.dart';

class MediaCard extends StatelessWidget {
  final Object item;
  final VoidCallback? onTap;

  /// Fixed width of the card; `null` fills the (width-bounded) parent.
  final double? width;

  const MediaCard({super.key, required this.item, this.onTap, this.width});

  @override
  Widget build(BuildContext context) {
    if (width != null) {
      return SizedBox(width: width, child: _buildCard(context, width));
    }

    return LayoutBuilder(
      builder: (context, constraints) {
        final cardWidth = constraints.maxWidth.isFinite
            ? constraints.maxWidth
            : null;
        return _buildCard(context, cardWidth);
      },
    );
  }

  Widget _buildCard(BuildContext context, double? cardWidth) {
    final meta = MediaItemMetadata.from(item);
    final subtitle = meta.getFormattedSubtitle(context);
    final textBlockHeight = MediaCardMetrics.textBlockHeight(context);

    return Card(
      margin: EdgeInsets.zero,
      clipBehavior: Clip.antiAlias,
      elevation: 1,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(MediaCardMetrics.radius),
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
                width: cardWidth,
                height: cardWidth,
              ),
            ),
            SizedBox(
              height: textBlockHeight,
              child: Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: MediaCardMetrics.textHorizontalPadding,
                  vertical: MediaCardMetrics.textVerticalPadding,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      meta.title,
                      maxLines: MediaCardMetrics.titleMaxLines,
                      overflow: TextOverflow.ellipsis,
                      style: MediaCardMetrics.titleStyle(
                        context.textTheme,
                      ).copyWith(color: context.colorScheme.primary),
                    ),
                    const SizedBox(
                      height: MediaCardMetrics.titleSubtitleGap,
                    ),
                    Text(
                      subtitle,
                      maxLines: MediaCardMetrics.subtitleMaxLines,
                      overflow: TextOverflow.ellipsis,
                      style: MediaCardMetrics.subtitleStyle(
                        context.textTheme,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
