import 'package:flutter/material.dart';
import 'package:music_are/core/l10n/l10n_extension.dart';
import 'package:music_are/core/theme/theme_extension.dart';

/// Visibility of a playlist as a compact pill.
///
/// A `null` value renders nothing: several playlists carry no meaningful
/// visibility (browse radios report `is_public: false` even though they are
/// algorithmic, not private), so the caller decides when the value applies.
class PlaylistVisibilityBadge extends StatelessWidget {
  final bool? isPublic;

  const PlaylistVisibilityBadge({super.key, required this.isPublic});

  @override
  Widget build(BuildContext context) {
    final visibility = isPublic;
    if (visibility == null) return const SizedBox.shrink();

    final colorScheme = context.colorScheme;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: colorScheme.surfaceContainerHighest.withValues(alpha: 0.6),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            visibility ? Icons.public_rounded : Icons.lock_outline_rounded,
            size: 14,
            color: colorScheme.onSurfaceVariant,
          ),
          const SizedBox(width: 4),
          Text(
            visibility ? context.l10n.playlistPublicLabel : context.l10n.playlistPrivateLabel,
            style: context.textTheme.labelMedium?.copyWith(
              color: colorScheme.onSurfaceVariant,
            ),
          ),
        ],
      ),
    );
  }
}
