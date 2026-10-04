import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:music_are/core/widgets/media/paginated_media_grid.dart';

void main() {
  testWidgets('the progressive skeleton completes the current row', (
    tester,
  ) async {
    // Four leading cells leave a partial last row for any column count > 1.
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: PaginatedMediaGrid(
            leading: List.generate(4, (_) => const SizedBox()),
            items: const [],
            isLoadingMore: true,
          ),
        ),
      ),
    );

    final grid = tester.widget<GridView>(find.byType(GridView));
    final delegate =
        grid.gridDelegate as SliverGridDelegateWithFixedCrossAxisCount;
    final columns = delegate.crossAxisCount;
    final childCount = grid.childrenDelegate.estimatedChildCount!;

    // The skeletons fill the row in progress, so the grid never ends with a
    // partial row (the old behaviour appended a whole row and overflowed).
    expect(childCount % columns, 0);
    expect(childCount - 4, columns - (4 % columns));
  });

  testWidgets('no skeleton appears when not loading more', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: PaginatedMediaGrid(
            leading: List.generate(4, (_) => const SizedBox()),
            items: const [],
          ),
        ),
      ),
    );

    final grid = tester.widget<GridView>(find.byType(GridView));
    expect(grid.childrenDelegate.estimatedChildCount, 4);
  });
}
