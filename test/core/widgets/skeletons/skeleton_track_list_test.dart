import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:music_are/core/widgets/skeletons/shimmer_box.dart';
import 'package:music_are/core/widgets/skeletons/skeleton_track_list.dart';

void main() {
  group('SkeletonTrackList trailing flags', () {
    Future<void> pumpList(
      WidgetTester tester,
      SkeletonTrackList list,
    ) async {
      await tester.pumpWidget(MaterialApp(home: Scaffold(body: list)));
      await tester.pump();
    }

    testWidgets('shows duration and options by default', (tester) async {
      await pumpList(tester, const SkeletonTrackList(count: 1));

      expect(find.byType(ShimmerBox), findsNWidgets(5));
    });

    testWidgets('hides only the duration shimmer', (tester) async {
      await pumpList(
        tester,
        const SkeletonTrackList(count: 1, showDuration: false),
      );

      expect(find.byType(ShimmerBox), findsNWidgets(4));
    });

    testWidgets('hides both trailing shimmers', (tester) async {
      await pumpList(
        tester,
        const SkeletonTrackList(
          count: 1,
          showDuration: false,
          showOptions: false,
        ),
      );

      expect(find.byType(ShimmerBox), findsNWidgets(3));
    });
  });
}
