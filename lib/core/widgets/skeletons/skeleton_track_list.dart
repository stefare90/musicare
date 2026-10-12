import 'package:flutter/material.dart';
import 'package:music_are/core/widgets/skeletons/shimmer_box.dart';

class SkeletonTrackList extends StatelessWidget {
  final bool showTitle;
  final int count;
  final bool showDuration;
  final bool showOptions;

  const SkeletonTrackList({
    super.key,
    this.showTitle = false,
    this.count = 5,
    this.showDuration = true,
    this.showOptions = true,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        if (showTitle)
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
            child: Align(
              alignment: Alignment.centerLeft,
              child: ShimmerBox(width: 200.0, height: 20.0),
            ),
          ),
        ...List.generate(
          count,
          (_) => ListTile(
            contentPadding: EdgeInsets.symmetric(
              horizontal: 16.0,
              vertical: 2.0,
            ),
            leading: ShimmerBox(
              width: 44.0,
              height: 44.0,
              borderRadius: BorderRadius.all(Radius.circular(8.0)),
            ),
            title: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                ShimmerBox(width: 150.0, height: 14.0),
                SizedBox(height: 6.0),
                ShimmerBox(width: 90.0, height: 10.0),
              ],
            ),
            trailing: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (showDuration) const ShimmerBox(width: 20.0, height: 10.0),
                if (showDuration && showOptions) const SizedBox(width: 20.0),
                if (showOptions)
                  const ShimmerBox(width: 10.0, height: 30.0),
                if (showOptions) const SizedBox(width: 20.0),
              ],
            ),
          ),
        ),
      ],
    );
  }
}
