import 'package:flutter/material.dart';
import 'package:music_are/core/theme/theme_extension.dart';
import 'package:music_are/core/widgets/media/media_card_metrics.dart';

/// A library "collection" card that has no remote artwork of its own, such as
/// *Liked Songs* (provider feedback) or a downloaded-tracks list.
///
/// It mirrors [MediaCard]'s cell geometry — square cover plus the exact text
/// block — so it can sit in the same grid as playlist/album/artist cards,
/// with a gradient and an icon standing in for the cover. Keeping it in the
/// grid (not as a separate row) is what makes the library visually uniform.
class LibraryCollectionCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final String? subtitle;
  final VoidCallback? onTap;

  const LibraryCollectionCard({
    super.key,
    required this.icon,
    required this.title,
    this.subtitle,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final textBlockHeight = MediaCardMetrics.textBlockHeight(context);
    final colors = [context.colorScheme.primary, context.colorScheme.tertiary];

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
              child: DecoratedBox(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: colors,
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                ),
                child: Center(
                  child: Icon(icon, size: 48, color: Colors.white),
                ),
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
                      title,
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
                      subtitle ?? '',
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
