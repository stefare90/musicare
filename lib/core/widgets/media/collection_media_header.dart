import 'package:flutter/material.dart';
import 'package:music_are/core/models/media_item_metadata.dart';
import 'package:music_are/core/widgets/media/cover_backdrop.dart';
import 'package:music_are/core/widgets/media/media_cover_image.dart';

class CollectionMediaHeader extends StatelessWidget {
  final MediaItemMetadata meta;
  final Widget child;

  static const double _coverSize = 220.0;
  static const double _topPadding = 56.0;
  static const double _haloBottomExtra = 150.0;

  const CollectionMediaHeader({
    super.key,
    required this.meta,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    return SliverToBoxAdapter(
      child: Stack(
        fit: StackFit.passthrough,
        children: [
          Positioned.fill(child: _backdrop(context)),
          Padding(
            padding: const EdgeInsets.only(
              top: _topPadding,
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
                  borderRadius: BorderRadius.circular(16.0),
                ),
                const SizedBox(height: 16),
                child,
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _backdrop(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final size = constraints.biggest;
        final coverBottom = _topPadding + _coverSize;
        final haloBottom = (coverBottom + _haloBottomExtra).clamp(
          1.0,
          size.height,
        );
        final verticalRadius = haloBottom / 2;
        final horizontalRadius = size.width * 0.75;
        final shortest = size.width < size.height ? size.width : size.height;
        final centerY = (((haloBottom / 2) / size.height) * 2 - 1).clamp(
          -1.0,
          1.0,
        );
        return CoverBackdrop(
          images: meta.images,
          mediaType: meta.mediaType,
          coverTarget: _coverSize,
          haloCenter: Alignment(0, centerY),
          haloRadius: (horizontalRadius / shortest).clamp(0.05, 2.0),
          haloScaleY: (verticalRadius / horizontalRadius).clamp(0.05, 1.5),
        );
      },
    );
  }
}
