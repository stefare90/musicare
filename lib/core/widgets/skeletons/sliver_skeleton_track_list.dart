import 'package:flutter/material.dart';
import 'package:music_are/core/widgets/skeletons/skeleton_track_list.dart';

class SliverSkeletonTrackList extends StatelessWidget {
  final bool showTitle;
  final int count;

  const SliverSkeletonTrackList({
    super.key,
    this.showTitle = false,
    this.count = 5,
  });

  @override
  Widget build(BuildContext context) {
    return SliverToBoxAdapter(
      child: SkeletonTrackList(showTitle: showTitle, count: count),
    );
  }
}
