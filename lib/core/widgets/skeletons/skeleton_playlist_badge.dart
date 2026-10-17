import 'package:flutter/material.dart';
import 'package:music_are/core/theme/theme_extension.dart';
import 'package:music_are/core/widgets/skeletons/shimmer_box.dart';

class SkeletonPlaylistBadge extends StatelessWidget {
  const SkeletonPlaylistBadge({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: context.colorScheme.surfaceContainerHighest.withValues(
          alpha: 0.6,
        ),
        borderRadius: BorderRadius.circular(999),
      ),
      child: const ShimmerBox(
        width: 46,
        height: 14,
        borderRadius: BorderRadius.all(Radius.circular(999)),
      ),
    );
  }
}
