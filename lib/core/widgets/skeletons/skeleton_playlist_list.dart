import 'package:flutter/material.dart';
import 'package:music_are/core/widgets/skeletons/shimmer_box.dart';

class SkeletonPlaylistList extends StatelessWidget {
  final int count;

  const SkeletonPlaylistList({super.key, this.count = 5});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: List.generate(
        count,
        (_) => const ListTile(
          leading: ShimmerBox(
            width: 48.0,
            height: 48.0,
            borderRadius: BorderRadius.all(Radius.circular(8.0)),
          ),
          title: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              ShimmerBox(width: 160.0, height: 14.0),
              SizedBox(height: 6.0),
              ShimmerBox(width: 100.0, height: 11.0),
            ],
          ),
        ),
      ),
    );
  }
}
