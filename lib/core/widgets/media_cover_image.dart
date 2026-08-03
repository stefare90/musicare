import 'package:flutter/material.dart';

class MediaCoverImage extends StatelessWidget {
  final String? imageUrl;
  final IconData fallbackIcon;
  final double? width;
  final double? height;
  final BorderRadius? borderRadius;
  final BoxFit fit;

  const MediaCoverImage({
    super.key,
    required this.imageUrl,
    this.fallbackIcon = Icons.music_note_rounded,
    this.width,
    this.height,
    this.borderRadius,
    this.fit = BoxFit.cover,
  });

  @override
  Widget build(BuildContext context) {
    Widget imageWidget;

    if (imageUrl != null && imageUrl!.isNotEmpty) {
      imageWidget = Image.network(
        imageUrl!,
        width: width,
        height: height,
        fit: fit,
        // Placeholder durante il download
        loadingBuilder: (context, child, loadingProgress) {
          if (loadingProgress == null) return child;
          return _buildPlaceholder(context);
        },
        errorBuilder: (_, __, ___) => _buildPlaceholder(context),
      );
    } else {
      imageWidget = _buildPlaceholder(context);
    }

    if (borderRadius != null) {
      return ClipRRect(borderRadius: borderRadius!, child: imageWidget);
    }

    return imageWidget;
  }

  Widget _buildPlaceholder(BuildContext context) {
    return Container(
      width: width,
      height: height,
      color: Theme.of(context).colorScheme.surfaceContainerHigh,
      child: Center(
        child: Icon(
          fallbackIcon,
          size: 40,
          color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.5),
        ),
      ),
    );
  }
}
