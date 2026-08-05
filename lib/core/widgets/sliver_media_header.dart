import 'package:flutter/material.dart';
import 'package:music_are/core/router/app_navigator.dart';
import 'package:music_are/core/theme/theme_extension.dart';
import 'package:music_are/core/widgets/media_cover_image.dart';

class SliverMediaHeader extends StatefulWidget {
  final String title;
  final String? subtitle;
  final String? imageUrl;
  final IconData fallbackIcon;
  final bool isCircular;
  final bool isSaved;
  final VoidCallback? onSaveTap;
  final VoidCallback? onExternalLinkTap;
  final VoidCallback? onShareTap;

  static const double _coverSize = 160.0;

  const SliverMediaHeader({
    super.key,
    required this.title,
    this.subtitle,
    this.imageUrl,
    this.fallbackIcon = Icons.music_note_rounded,
    this.isCircular = false,
    this.isSaved = false,
    this.onSaveTap,
    this.onExternalLinkTap,
    this.onShareTap,
  });

  @override
  State<SliverMediaHeader> createState() => _SliverMediaHeaderState();
}

class _SliverMediaHeaderState extends State<SliverMediaHeader> {
  final GlobalKey _largeTitleKey = GlobalKey();
  final ValueNotifier<bool> _isScrolledPast = ValueNotifier<bool>(false);

  @override
  void dispose() {
    _isScrolledPast.dispose();
    super.dispose();
  }

  void _checkTitlePosition(BuildContext context) {
    final renderBox =
        _largeTitleKey.currentContext?.findRenderObject() as RenderBox?;
    if (renderBox != null && renderBox.hasSize) {
      final position = renderBox.localToGlobal(Offset.zero);
      final topPadding = MediaQuery.of(context).padding.top;
      final appBarBottom = topPadding + kToolbarHeight;
      final largeTitleBottomY = position.dy + renderBox.size.height;
      final isPast = largeTitleBottomY <= appBarBottom;
      if (isPast != _isScrolledPast.value) {
        _isScrolledPast.value = isPast;
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return NotificationListener<ScrollNotification>(
      onNotification: (notification) {
        _checkTitlePosition(context);
        return false;
      },
      child: SliverMainAxisGroup(
        slivers: [
          SliverAppBar(
            pinned: true,
            elevation: 0,
            leading: IconButton(
              icon: const Icon(Icons.arrow_back),
              onPressed: () => AppNavigator.pop(context),
            ),
            title: ValueListenableBuilder<bool>(
              valueListenable: _isScrolledPast,
              builder: (context, isPast, child) {
                return AnimatedOpacity(
                  duration: const Duration(milliseconds: 180),
                  opacity: isPast ? 1.0 : 0.0,
                  child: Text(
                    widget.title,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: context.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                );
              },
            ),
            actions: [
              if (widget.onSaveTap != null)
                IconButton(
                  icon: Icon(
                    widget.isSaved
                        ? Icons.favorite_rounded
                        : Icons.favorite_border_rounded,
                    color: widget.isSaved ? context.colorScheme.primary : null,
                  ),
                  onPressed: widget.onSaveTap,
                  tooltip: 'Favorite',
                ),
              if (widget.onExternalLinkTap != null)
                IconButton(
                  icon: const Icon(Icons.open_in_new_rounded),
                  onPressed: widget.onExternalLinkTap,
                  tooltip: 'Open link',
                ),
              if (widget.onShareTap != null)
                IconButton(
                  icon: const Icon(Icons.share_rounded),
                  onPressed: widget.onShareTap,
                  tooltip: 'Share',
                ),
            ],
          ),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.only(
                top: 8.0,
                bottom: 24.0,
                left: 24.0,
                right: 24.0,
              ),
              child: Column(
                children: [
                  MediaCoverImage(
                    imageUrl: widget.imageUrl,
                    width: SliverMediaHeader._coverSize,
                    height: SliverMediaHeader._coverSize,
                    fallbackIcon: widget.fallbackIcon,
                    borderRadius: widget.isCircular
                        ? BorderRadius.circular(
                            SliverMediaHeader._coverSize / 2,
                          )
                        : BorderRadius.circular(16.0),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    widget.title,
                    key: _largeTitleKey,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    textAlign: TextAlign.center,
                    style: context.textTheme.headlineMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: context.colorScheme.primary,
                    ),
                  ),
                  if (widget.subtitle != null &&
                      widget.subtitle!.isNotEmpty) ...[
                    const SizedBox(height: 6),
                    Text(
                      widget.subtitle!,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      textAlign: TextAlign.center,
                      style: context.textTheme.bodyMedium?.copyWith(
                        color: context.colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
