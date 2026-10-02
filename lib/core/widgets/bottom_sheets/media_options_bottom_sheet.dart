import 'package:flutter/material.dart';
import 'package:music_are/core/models/media_item_metadata.dart';
import 'package:music_are/core/widgets/bottom_sheets/base_modal_bottom_sheet.dart';
import 'package:music_are/core/widgets/media/media_cover_image.dart';

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
    return BaseModalBottomSheet.show<T>(
      context: context,
      child: MediaOptionsBottomSheet(item: item, options: options),
    );
  }

  @override
  Widget build(BuildContext context) {
    final meta = MediaItemMetadata.from(item);

    return BaseModalBottomSheet(
      title: meta.title,
      subtitle: meta.getFormattedSubtitle(context),
      leading: MediaCoverImage(
        images: meta.images,
        mediaType: meta.mediaType,
        width: 48,
        height: 48,
        borderRadius: BorderRadius.circular(8),
      ),
      initialChildSize: 0.6,
      minChildSize: 0.35,
      maxChildSize: 0.8,
      builder: (context, scrollController) {
        return ListView(
          controller: scrollController,
          children: options,
        );
      },
    );
  }
}
