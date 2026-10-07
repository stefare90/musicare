import 'package:flutter/material.dart';
import 'package:music_are/core/widgets/skeletons/skeleton_section_row.dart';
import 'package:music_are/core/widgets/skeletons/skeleton_track_matrix.dart';

/// Mirrors the All view: track matrix + albums/artists/playlists rows.
class SkeletonSearchAll extends StatelessWidget {
  const SkeletonSearchAll({super.key});

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final columnWidth = screenWidth > 500 ? 360.0 : (screenWidth * 0.88);

    return ListView(
      physics: const AlwaysScrollableScrollPhysics(),
      padding: const EdgeInsets.symmetric(vertical: 12.0),
      children: [
        SkeletonTrackMatrix(
          showTitle: true,
          columnCount: 2,
          rowsCount: 3,
          totalHeight: 200.0,
          columnWidth: columnWidth,
        ),
        const SkeletonSectionRow(showTitle: true),
        const SkeletonSectionRow(showTitle: true),
        const SkeletonSectionRow(showTitle: true),
      ],
    );
  }
}

