import 'package:flutter/material.dart';
import 'package:gyawun_metadata_sdk/metadata/models/track.dart';
import 'package:music_are/core/models/media_item_metadata.dart';
import 'package:music_are/core/models/media_type.dart';
import 'package:music_are/core/widgets/error_card.dart';
import 'package:music_are/core/widgets/media/sliver_media_app_bar.dart';
import 'package:music_are/core/widgets/media/sliver_media_header.dart';
import 'package:music_are/core/widgets/media/sliver_track_list.dart';

class SliverMediaDetailLayout extends StatefulWidget {
  final MediaItemMetadata? metadata;
  final bool isSaved;
  final bool isLoading;
  final Object? error;
  final List<Track> tracks;
  final bool hasMoreTracks;
  final MediaType listType;
  final VoidCallback? onRetry;
  final VoidCallback? onLoadMore;
  final VoidCallback? onSaveTap;
  final VoidCallback? onOptionsTap;
  final void Function(Track track)? onTrackTap;
  final void Function(Track track)? onTrackOptionsTap;

  const SliverMediaDetailLayout({
    super.key,
    required this.metadata,
    this.isSaved = false,
    this.isLoading = false,
    this.error,
    this.tracks = const [],
    this.hasMoreTracks = false,
    required this.listType,
    this.onRetry,
    this.onLoadMore,
    this.onSaveTap,
    this.onOptionsTap,
    this.onTrackTap,
    this.onTrackOptionsTap,
  });

  @override
  State<SliverMediaDetailLayout> createState() =>
      _SliverMediaDetailLayoutState();
}

class _SliverMediaDetailLayoutState extends State<SliverMediaDetailLayout> {
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
            else if (!widget.isLoading)
              SliverTrackList(
                tracks: widget.tracks,
                listType: widget.listType,
                hasMore: widget.hasMoreTracks,
                onLoadMore: widget.onLoadMore,
                onTrackTap: widget.onTrackTap,
                onTrackOptionsTap: widget.onTrackOptionsTap,
              )
            else
              const SliverFillRemaining(
                child: Center(child: CircularProgressIndicator()),
              ),
          ],
        ),
      ),
    );
  }
}
