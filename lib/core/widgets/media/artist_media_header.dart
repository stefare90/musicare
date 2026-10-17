import 'package:flutter/material.dart';
import 'package:music_are/core/models/media_item_metadata.dart';
import 'package:music_are/core/widgets/media/media_cover_image.dart';

class ArtistMediaHeader extends StatelessWidget {
  final MediaItemMetadata meta;
  final Widget child;

  static const double _maxHeight = 520.0;

  const ArtistMediaHeader({super.key, required this.meta, required this.child});

  @override
  Widget build(BuildContext context) {
    return SliverToBoxAdapter(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          LayoutBuilder(
            builder: (context, constraints) {
              final height = constraints.maxWidth.clamp(0.0, _maxHeight);
              return SizedBox(
                height: height,
                width: double.infinity,
                child: ShaderMask(
                  blendMode: BlendMode.dstIn,
                  shaderCallback: (rect) => _mask().createShader(rect),
                  child: MediaCoverImage(
                    images: meta.images,
                    mediaType: meta.mediaType,
                    fit: BoxFit.cover,
                    borderRadius: BorderRadius.circular(24.0),
                  ),
                ),
              );
            },
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(24.0, 8.0, 24.0, 24.0),
            child: child,
          ),
        ],
      ),
    );
  }

  static LinearGradient _mask() {
    final fade = Colors.white.withValues(alpha: 0.0);
    return LinearGradient(
      begin: Alignment.topCenter,
      end: Alignment.bottomCenter,
      colors: [Colors.white, Colors.white, fade],
      stops: const [0.0, 0.55, 1.0],
    );
  }
}
