import 'package:flutter/material.dart';
import 'package:music_are/core/models/media_item_metadata.dart';
import 'package:music_are/core/widgets/media/sliver_media_app_bar.dart';
import 'package:music_are/core/widgets/media/sliver_media_header.dart';
import 'package:music_are/core/widgets/skeletons/sliver_skeleton_track_list.dart';

class SliverMediaScaffold extends StatefulWidget {
  final MediaItemMetadata? metadata;
  final bool isSaved;
  final bool isLoading;

  /// Shown when there is nothing to display; the caller composes it, this
  /// scaffold only places it.
  final Widget? statusCard;

  final VoidCallback? onSaveTap;
  final VoidCallback? onOptionsTap;

  final Widget? headerBadge;
  final List<Widget> slivers;

  const SliverMediaScaffold({
    super.key,
    required this.metadata,
    this.isSaved = false,
    this.isLoading = false,
    this.statusCard,
    this.onSaveTap,
    this.onOptionsTap,
    this.headerBadge,
    this.slivers = const [],
  });

  @override
  State<SliverMediaScaffold> createState() => _SliverMediaScaffoldState();
}

class _SliverMediaScaffoldState extends State<SliverMediaScaffold> {
  final GlobalKey _largeTitleKey = GlobalKey();
  final ValueNotifier<bool> _isScrolledPast = ValueNotifier<bool>(false);

  @override
  void dispose() {
    _isScrolledPast.dispose();
    super.dispose();
  }

  void _checkTitlePosition(BuildContext context) {
    if (!mounted) return;
    final titleContext = _largeTitleKey.currentContext;
    if (titleContext == null || !titleContext.mounted) return;

    final renderBox = titleContext.findRenderObject() as RenderBox?;
    if (renderBox != null && renderBox.hasSize && renderBox.attached) {
      try {
        final position = renderBox.localToGlobal(Offset.zero);
        final topPadding = MediaQuery.paddingOf(context).top;
        final appBarBottom = topPadding + kToolbarHeight;
        final largeTitleBottomY = position.dy + renderBox.size.height;
        final isPast = largeTitleBottomY <= appBarBottom;
        if (isPast != _isScrolledPast.value) {
          _isScrolledPast.value = isPast;
        }
      } catch (_) {}
    }
  }

  @override
  Widget build(BuildContext context) {
    final metadata = widget.metadata;
    return Scaffold(
      resizeToAvoidBottomInset: false,
      body: NotificationListener<ScrollNotification>(
        onNotification: (notification) {
          if (notification is ScrollUpdateNotification) {
            WidgetsBinding.instance.addPostFrameCallback((_) {
              if (mounted) {
                _checkTitlePosition(context);
              }
            });
          }
          return false;
        },
        child: CustomScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          slivers: [
            if (metadata != null)
              SliverMediaAppBar(
                title: metadata.title,
                isSaved: widget.isSaved,
                isScrolledPast: _isScrolledPast,
                onSaveTap: widget.onSaveTap,
                onOptionsTap: widget.onOptionsTap,
              ),
            if (metadata != null)
              SliverMediaHeader(
                meta: metadata,
                titleKey: _largeTitleKey,
                badge: widget.headerBadge,
              ),
            if (widget.statusCard != null)
              SliverFillRemaining(
                hasScrollBody: false,
                child: Center(child: widget.statusCard),
              )
            else if (widget.isLoading)
              const SliverSkeletonTrackList(count: 6)
            else
              ...widget.slivers,
          ],
        ),
      ),
    );
  }
}
