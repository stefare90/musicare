import 'package:flutter/material.dart';
import 'package:gyawun_metadata_sdk/metadata/models/image.dart' as sdk;
import 'package:music_are/core/models/media_type.dart';

class MediaCoverImage extends StatelessWidget {
  final List<sdk.Image>? images;
  final MediaType mediaType;
  final double? width;
  final double? height;
  final BorderRadius? borderRadius;
  final BoxFit fit;

  const MediaCoverImage({
    super.key,
    this.images,
    required this.mediaType,
    this.width,
    this.height,
    this.borderRadius,
    this.fit = BoxFit.cover,
  });

  IconData get _effectiveFallbackIcon => mediaType.defaultIcon;

  String? _getBestImageUrl(List<String> validUrls) {
    if (validUrls.isEmpty) return null;
    if (width != null && width! < 100 && validUrls.length > 1) {
      return validUrls.last;
    }
    return validUrls.first;
  }

  @override
  Widget build(BuildContext context) {
    final validUrls =
        images
            ?.map((i) => i.url)
            .where((url) => url.trim().isNotEmpty)
            .toList() ??
        [];
    Widget imageWidget;
    if (mediaType == MediaType.playlist && validUrls.length >= 4) {
      imageWidget = _buildMosaic(context, validUrls.take(4).toList());
    } else {
      final bestUrl = _getBestImageUrl(validUrls);
      if (bestUrl != null) {
        imageWidget = Image.network(
          bestUrl,
          width: width,
          height: height,
          fit: fit,
          loadingBuilder: (context, child, loadingProgress) {
            if (loadingProgress == null) return child;
            return _buildPlaceholder(context);
          },
          errorBuilder: (_, __, ___) => _buildPlaceholder(context),
        );
      } else {
        imageWidget = _buildPlaceholder(context);
      }
    }
    if (borderRadius != null) {
      return ClipRRect(borderRadius: borderRadius!, child: imageWidget);
    }
    return imageWidget;
  }

  Widget _buildMosaic(BuildContext context, List<String> urls) {
    return SizedBox(
      width: width,
      height: height,
      child: Column(
        children: [
          Expanded(
            child: Row(
              children: [
                Expanded(child: _buildTileImage(context, urls[0])),
                Expanded(child: _buildTileImage(context, urls[1])),
              ],
            ),
          ),
          Expanded(
            child: Row(
              children: [
                Expanded(child: _buildTileImage(context, urls[2])),
                Expanded(child: _buildTileImage(context, urls[3])),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTileImage(BuildContext context, String url) {
    return Image.network(
      url,
      width: double.infinity,
      height: double.infinity,
      fit: BoxFit.cover,
      errorBuilder: (_, __, ___) =>
          Container(color: Theme.of(context).colorScheme.surfaceContainerHigh),
    );
  }

  Widget _buildPlaceholder(BuildContext context) {
    return Container(
      width: width,
      height: height,
      color: Theme.of(context).colorScheme.surfaceContainerHigh,
      child: Center(
        child: Icon(
          _effectiveFallbackIcon,
          size: (width != null && width! < 60) ? 24 : 40,
          color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.5),
        ),
      ),
    );
  }
}
