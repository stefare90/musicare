import 'package:flutter/material.dart';
import 'package:music_are/core/models/media_item_metadata.dart';
import 'package:music_are/core/widgets/error_card.dart';
import 'package:music_are/core/widgets/media/sliver_media_app_bar.dart';
import 'package:music_are/core/widgets/media/sliver_media_header.dart';
import 'package:music_are/core/widgets/skeletons/sliver_skeleton_track_list.dart';

class SliverMediaScaffold extends StatefulWidget {
  final MediaItemMetadata? metadata;
  final bool isSaved;
  final bool isLoading;
  final Object? error;
  final VoidCallback? onRetry;
  final VoidCallback? onSaveTap;
  final VoidCallback? onOptionsTap;
  final List<Widget> slivers;

  const SliverMediaScaffold({
    super.key,
    required this.metadata,
    this.isSaved = false,
    this.isLoading = false,
    this.error,
    this.onRetry,
    this.onSaveTap,
    this.onOptionsTap,
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
    final metadata = widget.metadata;
    return Scaffold(
      body: NotificationListener<ScrollNotification>(
        onNotification: (notification) {
          _checkTitlePosition(context);
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
              SliverMediaHeader(meta: metadata, titleKey: _largeTitleKey),
            if (widget.error != null)
              SliverFillRemaining(
                child: Center(
                  child: ErrorCard(
                    error: widget.error!,
                    onRetry: widget.onRetry,
                  ),
                ),
              )
            else if (widget.isLoading)
              SliverSkeletonTrackList(showTitle: false, count: 6)
            else
              ...widget.slivers,
          ],
        ),
      ),
    );
  }
}
