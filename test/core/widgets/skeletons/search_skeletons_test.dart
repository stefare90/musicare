import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:gyawun_metadata_sdk/metadata/models/album.dart';
import 'package:music_are/core/l10n/app_localizations.dart';
import 'package:music_are/core/widgets/media/media_card.dart';
import 'package:music_are/core/widgets/media/media_card_metrics.dart';
import 'package:music_are/core/widgets/media/section_row.dart';
import 'package:music_are/core/widgets/skeletons/shimmer_box.dart';
import 'package:music_are/core/widgets/skeletons/skeleton_media_grid.dart';
import 'package:music_are/core/widgets/skeletons/skeleton_search_all.dart';
import 'package:music_are/core/widgets/skeletons/skeleton_section_row.dart';
import 'package:music_are/core/widgets/skeletons/skeleton_track_matrix.dart';

void main() {
  group('Search Skeletons Tests', () {
    testWidgets(
      'SkeletonMediaGrid renders specified number of skeleton items and scrolls',
      (tester) async {
        await tester.pumpWidget(
          const MaterialApp(
            home: Scaffold(
              body: SkeletonMediaGrid(itemCount: 6),
            ),
          ),
        );

        expect(find.byType(GridView), findsOneWidget);
        expect(find.byType(ShimmerBox), findsNWidgets(6));
      },
    );

    testWidgets('SkeletonSearchAll renders matrix and two section rows', (
      tester,
    ) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: SkeletonSearchAll(),
          ),
        ),
      );

      expect(find.byType(SkeletonTrackMatrix), findsOneWidget);
      expect(find.byType(SkeletonSectionRow), findsNWidgets(2));
      expect(find.byType(ListView), findsWidgets);
    });

    testWidgets('SkeletonSectionRow cards match the real MediaCard footprint', (
      tester,
    ) async {
      final album = Album(
        id: 'al1',
        name: 'Abbey Road',
        artists: const [],
        releaseDate: '1969',
        externalUri: '',
        totalTracks: 17,
        albumType: AlbumType.album,
      );

      // Real card footprint inside a SectionRow.
      await tester.pumpWidget(
        MaterialApp(
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: Scaffold(
            body: SectionRow(title: 'Albums', items: [album]),
          ),
        ),
      );
      final realSize = tester.getSize(find.byType(MediaCard).first);

      // Skeleton card footprint.
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(body: SkeletonSectionRow()),
        ),
      );
      final skeletonCard = tester
          .widgetList<ShimmerBox>(find.byType(ShimmerBox))
          .firstWhere(
            (box) => box.width == MediaCardMetrics.rowCardWidth,
          );

      expect(skeletonCard.width, realSize.width);
      expect(skeletonCard.height, realSize.height);
    });

    testWidgets('SkeletonMediaGrid cell matches MediaCardMetrics cell', (
      tester,
    ) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(body: SkeletonMediaGrid(itemCount: 4)),
        ),
      );

      final firstBox = tester.widget<ShimmerBox>(find.byType(ShimmerBox).first);
      // Default test viewport is 800x600 logical pixels.
      final columns = MediaCardMetrics.gridColumns(800);
      final cell = MediaCardMetrics.gridCellWidth(800, columns);

      expect(firstBox.width, closeTo(cell, 0.01));
      expect(firstBox.height, greaterThan(cell));
    });
  });
}

