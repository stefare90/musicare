import 'package:flutter/material.dart';
import 'package:music_are/core/models/media_item_metadata.dart';
import 'package:music_are/core/theme/theme_extension.dart';
import 'package:music_are/core/widgets/media_cover_image.dart';

class MediaOptionsBottomSheet extends StatelessWidget {
  final Object item;
  final List<Widget> options;

  const MediaOptionsBottomSheet({
    super.key,
    required this.item,
    required this.options,
  });

  static Future<T?> show<T>({
    required BuildContext context,
    required Object item,
    required List<Widget> options,
  }) {
    return showModalBottomSheet<T>(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20.0)),
      ),
      builder: (bottomSheetContext) =>
          MediaOptionsBottomSheet(item: item, options: options),
    );
  }

  @override
  Widget build(BuildContext context) {
    final meta = MediaItemMetadata.from(item);

    return SafeArea(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const SizedBox(height: 8),
          Container(
            width: 36,
            height: 4,
            decoration: BoxDecoration(
              color: context.colorScheme.onSurfaceVariant.withValues(
                alpha: 0.4,
              ),
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(height: 8),
          ListTile(
            leading: MediaCoverImage(
              imageUrl: meta.imageUrl,
              width: 44,
              height: 44,
              borderRadius: BorderRadius.circular(8),
            ),
            title: Text(
              meta.title,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: context.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            subtitle: Text(
              meta.toFormattedSubtitle(context),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: context.textTheme.bodyMedium?.copyWith(
                color: context.colorScheme.onSurfaceVariant,
              ),
            ),
          ),
          const Divider(),
          ...options,
        ],
      ),
    );
  }
}
