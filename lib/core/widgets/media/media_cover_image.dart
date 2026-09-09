import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:gyawun_metadata_sdk/metadata/models/image.dart' as sdk;
import 'package:music_are/core/models/media_type.dart';
import 'package:music_are/core/theme/theme_extension.dart';

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

  String? _getBestImageUrl(BuildContext context, List<sdk.Image>? images) {
    if (images == null || images.isEmpty) return null;
    final validImages = images.where((i) => i.url.trim().isNotEmpty).toList();
    if (validImages.isEmpty) return null;
    final withWidth = validImages
        .where((i) => i.width != null && i.width! > 0)
        .toList();
    if (withWidth.isNotEmpty) {
      withWidth.sort((a, b) => a.width!.compareTo(b.width!));
      final double? targetDp = width ?? height;
      if (targetDp == null) {
        return withWidth.last.url;
      }
      final mediaQuery = MediaQuery.maybeOf(context);
      final pixelRatio = mediaQuery?.devicePixelRatio ?? 2.0;
      final targetPx = targetDp * pixelRatio;
      for (final img in withWidth) {
        if (img.width! >= targetPx) {
          return img.url;
        }
      }
      return withWidth.last.url;
    }
    return validImages.first.url;
  }

  List<String> _getMosaicUrls(List<String> urls) {
    if (urls.length == 2) {
      return [urls[0], urls[1], urls[1], urls[0]];
    }
    if (urls.length == 3) {
      return [urls[0], urls[1], urls[2], urls[0]];
    }
    return urls.take(4).toList();
  }

  @override
  Widget build(BuildContext context) {
    final validUrls = images
            ?.map((i) => i.url)
            .where((url) => url.trim().isNotEmpty)
            .toList() ??
        [];
    Widget imageWidget;
    if (mediaType == MediaType.playlist && validUrls.length >= 2) {
      imageWidget = _buildMosaic(context, _getMosaicUrls(validUrls));
    } else {
      final bestUrl = _getBestImageUrl(context, images);
      if (bestUrl != null) {
        imageWidget = CachedNetworkImage(
          imageUrl: bestUrl,
          width: width,
          height: height,
          fit: fit,
          fadeInDuration: const Duration(milliseconds: 180),
          placeholder: (context, url) => _buildLoadingPlaceholder(context),
          errorWidget: (context, url, error) => _buildFallbackIcon(context),
        );
      } else {
        imageWidget = _buildFallbackIcon(context);
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
    return CachedNetworkImage(
      imageUrl: url,
      width: double.infinity,
      height: double.infinity,
      fit: BoxFit.cover,
      fadeInDuration: const Duration(milliseconds: 180),
      placeholder: (_, _) => _buildLoadingPlaceholder(context),
      errorWidget: (_, _, _) =>
          Container(color: context.colorScheme.surfaceContainerHigh),
    );
  }

  Widget _buildLoadingPlaceholder(BuildContext context) {
    return Container(
      width: width,
      height: height,
      color: context.colorScheme.surfaceContainerHigh.withValues(alpha: 0.7),
    );
  }

  Widget _buildFallbackIcon(BuildContext context) {
    return Container(
      width: width,
      height: height,
      color: context.colorScheme.surfaceContainerHigh,
      child: Center(
        child: Icon(
          _effectiveFallbackIcon,
          size: (width != null && width! < 60) ? 24 : 40,
          color: context.colorScheme.primary.withValues(alpha: 0.5),
        ),
      ),
    );
  }
}
