import 'package:flutter/material.dart';
import 'package:music_are/core/models/media_type.dart';
import 'package:music_are/core/theme/theme_extension.dart';

class CoverFallback extends StatelessWidget {
  final MediaType mediaType;
  final double? width;
  final double? height;

  const CoverFallback({
    super.key,
    required this.mediaType,
    this.width,
    this.height,
  });

  @override
  Widget build(BuildContext context) {
    final scheme = context.colorScheme;
    final base = scheme.surfaceContainerHighest;
    Color tint(double amount) => Color.lerp(
      Color.lerp(base, scheme.primary, amount)!,
      Colors.black,
      0.15,
    )!;

    return DecoratedBox(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [tint(0.30), tint(0.05)],
        ),
      ),
      child: SizedBox(
        width: width,
        height: height,
        child: LayoutBuilder(
          builder: (context, constraints) {
            final side = constraints.biggest.shortestSide;
            final iconSize = side.isFinite && side > 0 ? side * 1.15 : 96.0;
            return ClipRect(
              child: Align(
                alignment: const Alignment(1.05, 1.1),
                child: Icon(
                  mediaType.defaultIcon,
                  size: iconSize,
                  color: scheme.primary.withValues(alpha: 0.12),
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}
