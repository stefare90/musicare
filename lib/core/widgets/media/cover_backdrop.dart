import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:musicare_metadata_host_sdk/metadata/models/image.dart' as sdk;
import 'package:music_are/core/models/media_type.dart';
import 'package:music_are/core/widgets/media/media_cover_image.dart';

/// Blurred cover with a colored halo that fades into [background].
class CoverBackdrop extends StatelessWidget {
  final List<sdk.Image> images;
  final MediaType mediaType;
  final double? coverTarget;
  final Alignment haloCenter;
  final double haloRadius;
  final double haloScaleY;
  final double? opacity;
  final double blur;
  final Color? background;

  const CoverBackdrop({
    super.key,
    required this.images,
    required this.mediaType,
    required this.haloCenter,
    required this.haloRadius,
    this.coverTarget,
    this.haloScaleY = 1.0,
    this.opacity,
    this.blur = 40.0,
    this.background,
  });

  @override
  Widget build(BuildContext context) {
    final bg = background ?? Theme.of(context).scaffoldBackgroundColor;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return IgnorePointer(
      child: ClipRect(
        child: Stack(
          fit: StackFit.expand,
          children: [
            Opacity(
              opacity: opacity ?? (isDark ? 0.35 : 0.18),
              child: ImageFiltered(
                imageFilter: ImageFilter.blur(sigmaX: blur, sigmaY: blur),
                child: MediaCoverImage(
                  images: images,
                  mediaType: mediaType,
                  width: coverTarget,
                  height: coverTarget,
                  fit: BoxFit.cover,
                  showLoadingPlaceholder: false,
                ),
              ),
            ),
            DecoratedBox(
              decoration: BoxDecoration(
                gradient: _haloGradient(
                  background: bg,
                  center: haloCenter,
                  radius: haloRadius,
                  scaleY: haloScaleY,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  static RadialGradient _haloGradient({
    required Color background,
    required Alignment center,
    required double radius,
    required double scaleY,
  }) {
    const rampStart = 0.5;
    const samples = 24;
    final colors = <Color>[];
    final stops = <double>[];
    for (var i = 0; i <= samples; i++) {
      final t = i / samples;
      colors.add(background.withValues(alpha: _smoothStep(t, rampStart, 1.0)));
      stops.add(t);
    }
    return RadialGradient(
      center: center,
      radius: radius.clamp(0.05, 2.0),
      transform: _EllipseTransform(
        center: center,
        scaleY: scaleY.clamp(0.05, 1.5),
      ),
      colors: colors,
      stops: stops,
    );
  }
}

class _EllipseTransform extends GradientTransform {
  final Alignment center;
  final double scaleY;

  const _EllipseTransform({required this.center, required this.scaleY});

  @override
  Matrix4? transform(Rect bounds, {TextDirection? textDirection}) {
    final centerDy = bounds.center.dy + center.y * bounds.height / 2;
    // translate(0, c) * scale(1, s) * translate(0, -c): squashes the circle
    // into an ellipse anchored on the halo centre.
    return Matrix4.identity()
      ..setEntry(1, 1, scaleY)
      ..setEntry(1, 3, centerDy * (1 - scaleY));
  }
}

double _smoothStep(double x, double edge0, double edge1) {
  final t = ((x - edge0) / (edge1 - edge0)).clamp(0.0, 1.0);
  return t * t * (3.0 - 2.0 * t);
}
