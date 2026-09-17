import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:music_are/core/theme/app_theme.dart';
import 'package:music_are/core/widgets/media/media_card_metrics.dart';

void main() {
  Widget wrap({required Widget child, double textScale = 1.0}) {
    return MaterialApp(
      theme: AppTheme.darkTheme,
      home: MediaQuery(
        data: MediaQueryData(textScaler: TextScaler.linear(textScale)),
        child: Scaffold(body: child),
      ),
    );
  }

  Future<T> measure<T>(
    WidgetTester tester,
    T Function(BuildContext context) reader, {
    double textScale = 1.0,
  }) async {
    late T value;
    await tester.pumpWidget(
      wrap(
        textScale: textScale,
        child: Builder(
          builder: (context) {
            value = reader(context);
            return const SizedBox.shrink();
          },
        ),
      ),
    );
    return value;
  }

  group('MediaCardMetrics', () {
    testWidgets('textBlockHeight grows with textScaler', (tester) async {
      final heights = <double>[];
      for (final scale in [1.0, 1.3, 1.5, 2.0]) {
        heights.add(
          await measure(tester, MediaCardMetrics.textBlockHeight,
              textScale: scale),
        );
      }

      expect(heights[0], greaterThan(0));
      for (var i = 1; i < heights.length; i++) {
        expect(heights[i], greaterThan(heights[i - 1]),
            reason: 'textBlockHeight must increase with textScaler');
      }
    });

    testWidgets('rowHeight is rowCardWidth + textBlockHeight', (tester) async {
      final textBlock = await measure(tester, MediaCardMetrics.textBlockHeight);
      final row = await measure(tester, MediaCardMetrics.rowHeight);
      expect(row, MediaCardMetrics.rowCardWidth + textBlock);
    });

    testWidgets('cardHeight is cardWidth + textBlockHeight', (tester) async {
      final textBlock = await measure(tester, MediaCardMetrics.textBlockHeight);
      final card = await measure(
        tester,
        (context) => MediaCardMetrics.cardHeight(context, 140.0),
      );
      expect(card, 140.0 + textBlock);
    });

    testWidgets('sectionTitleHeight grows with textScaler', (tester) async {
      final h1 = await measure(tester, MediaCardMetrics.sectionTitleHeight);
      final h2 = await measure(tester, MediaCardMetrics.sectionTitleHeight,
          textScale: 2.0);
      expect(h1, greaterThan(0));
      expect(h2, greaterThan(h1));
    });

    test('gridColumns is deterministic across reference viewports', () {
      expect(MediaCardMetrics.gridColumns(320), 2);
      expect(MediaCardMetrics.gridColumns(360), 2);
      expect(MediaCardMetrics.gridColumns(411), 2);
      expect(MediaCardMetrics.gridColumns(800), 4);
    });

    test('gridCellWidth respects the minimum card width', () {
      for (final width in [320.0, 360.0, 411.0, 800.0]) {
        final columns = MediaCardMetrics.gridColumns(width);
        final cell = MediaCardMetrics.gridCellWidth(width, columns);
        expect(cell, greaterThanOrEqualTo(MediaCardMetrics.minCardWidth));
      }
    });

    test('gridDelegate sizes each cell as square cover + text block', () {
      for (final width in [320.0, 360.0, 411.0, 800.0]) {
        const textBlock = 72.0;
        final delegate = MediaCardMetrics.gridDelegate(
          maxWidth: width,
          textBlockHeight: textBlock,
        );
        final columns = MediaCardMetrics.gridColumns(width);
        final cell = MediaCardMetrics.gridCellWidth(width, columns);

        expect(delegate.crossAxisCount, columns);
        expect(delegate.crossAxisSpacing, MediaCardMetrics.gap);
        expect(delegate.mainAxisSpacing, MediaCardMetrics.gap);
        expect(delegate.mainAxisExtent, cell + textBlock);
      }
    });

    group('pageSizeForColumns', () {
      test('returns pageSize unchanged when columns is not positive', () {
        expect(MediaCardMetrics.pageSizeForColumns(20, 0), 20);
        expect(MediaCardMetrics.pageSizeForColumns(20, -3), 20);
      });

      test('rounds up to the nearest multiple of the columns', () {
        expect(MediaCardMetrics.pageSizeForColumns(20, 2), 20);
        expect(MediaCardMetrics.pageSizeForColumns(20, 3), 21);
        expect(MediaCardMetrics.pageSizeForColumns(20, 4), 20);
        expect(MediaCardMetrics.pageSizeForColumns(10, 3), 12);
        expect(MediaCardMetrics.pageSizeForColumns(10, 4), 12);
        expect(MediaCardMetrics.pageSizeForColumns(1, 4), 4);
      });

      test('result is always a multiple of columns', () {
        for (final columns in [2, 3, 4, 5, 8]) {
          final result = MediaCardMetrics.pageSizeForColumns(20, columns);
          expect(result % columns, 0,
              reason: 'limit must be a multiple of $columns columns');
          expect(result, greaterThanOrEqualTo(20));
        }
      });
    });
  });
}
