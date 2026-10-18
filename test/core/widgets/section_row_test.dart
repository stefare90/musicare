import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:musicare_metadata_host_sdk/musicare_metadata_host_sdk.dart';
import 'package:music_are/core/l10n/app_localizations.dart';
import 'package:music_are/core/widgets/media/media_card.dart';
import 'package:music_are/core/widgets/media/media_card_error.dart';
import 'package:music_are/core/widgets/media/media_card_metrics.dart';
import 'package:music_are/core/widgets/media/section_row.dart';

void main() {
  Widget buildTestableWidget({required Widget child, double textScale = 1.0}) {
    return MaterialApp(
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      builder: (context, widget) => MediaQuery(
        data: MediaQuery.of(context).copyWith(
          textScaler: TextScaler.linear(textScale),
        ),
        child: widget!,
      ),
      home: Scaffold(body: child),
    );
  }

  Album buildAlbum(String name) {
    return Album(
      id: name,
      name: name,
      artists: const [],
      releaseDate: '1969',
      externalUri: '',
      totalTracks: 17,
      albumType: AlbumType.album,
    );
  }

  group('SectionRow Widget Tests', () {
    final testAlbum = buildAlbum('Abbey Road');

    testWidgets('renders title, description and list of MediaCards', (
      tester,
    ) async {
      await tester.pumpWidget(
        buildTestableWidget(
          child: SectionRow(
            title: 'Rock Classics',
            description: 'Best of Rock',
            items: [testAlbum],
          ),
        ),
      );

      expect(find.text('Rock Classics'), findsOneWidget);
      expect(find.text('Best of Rock'), findsOneWidget);
      expect(find.text('Abbey Road'), findsOneWidget);
    });

    testWidgets('leaves room below the card for its shadow', (tester) async {
      await tester.pumpWidget(
        buildTestableWidget(
          child: SectionRow(title: 'Rock Classics', items: [testAlbum]),
        ),
      );

      final cardRect = tester.getRect(find.byType(MediaCard));
      final rowRect = tester.getRect(find.byType(ListView));

      expect(
        rowRect.bottom - cardRect.bottom,
        greaterThanOrEqualTo(MediaCardMetrics.cardShadowInset),
      );
    });

    testWidgets('renders SizedBox.shrink when items list is empty', (
      tester,
    ) async {
      await tester.pumpWidget(
        buildTestableWidget(
          child: const SectionRow(title: 'Empty Section', items: []),
        ),
      );

      expect(find.text('Empty Section'), findsNothing);
      expect(find.byType(SizedBox), findsOneWidget);
    });

    for (final scale in [1.0, 2.0]) {
      testWidgets(
        'error card in the row is as wide as the real cards at $scale',
        (tester) async {
          await tester.pumpWidget(
            buildTestableWidget(
              textScale: scale,
              child: SectionRow(
                title: 'Rock Classics',
                items: [testAlbum],
                loadMoreError: Exception('Network timeout'),
              ),
            ),
          );

          expect(
            tester.getSize(find.byType(MediaCard)).width,
            MediaCardMetrics.rowCardWidth,
          );
          expect(
            tester.getSize(find.byType(MediaCardError)).width,
            MediaCardMetrics.rowCardWidth,
          );
          expect(tester.takeException(), isNull);
        },
      );
    }

    for (final scale in [1.0, 1.3, 1.5, 2.0]) {
      for (final viewport in const [
        Size(320, 640),
        Size(360, 800),
        Size(411, 891),
        Size(800, 600),
      ]) {
        testWidgets(
          'renders without overflow (scale $scale, '
          '${viewport.width.toInt()}x${viewport.height.toInt()})',
          (tester) async {
            tester.view.physicalSize = viewport;
            tester.view.devicePixelRatio = 1.0;
            addTearDown(tester.view.reset);

            await tester.pumpWidget(
              buildTestableWidget(
                textScale: scale,
                child: SectionRow(
                  title: 'Albums',
                  items: [
                    buildAlbum('Abbey Road'),
                    buildAlbum('Let It Be'),
                    buildAlbum('Revolver'),
                  ],
                ),
              ),
            );

            expect(find.byType(MediaCard), findsWidgets);
            expect(tester.takeException(), isNull);
          },
        );
      }
    }
  });
}
