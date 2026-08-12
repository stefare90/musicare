import 'package:flutter/material.dart';
import 'package:music_are/core/widgets/skeletons/shimmer_box.dart';

class SkeletonSectionRow extends StatelessWidget {
  final bool showTitle;

  const SkeletonSectionRow({super.key, this.showTitle = true});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (showTitle)
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
            child: ShimmerBox(width: 200.0, height: 20.0),
          ),
        SizedBox(
          height: 185.0,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            physics: const NeverScrollableScrollPhysics(),
            padding: const EdgeInsets.symmetric(horizontal: 10.0),
            itemCount: 4,
            itemBuilder: (context, index) {
              return const Padding(
                padding: EdgeInsets.symmetric(horizontal: 4.0),
                child: ShimmerBox(
                  width: 135.0,
                  height: 180.0,
                  borderRadius: BorderRadius.all(Radius.circular(14.0)),
                ),
              );
            },
          ),
        ),
        const SizedBox(height: 12.0),
      ],
    );
  }
}
