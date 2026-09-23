import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:musicare_metadata_host_sdk/musicare_metadata_host_sdk.dart';
import 'package:music_are/core/l10n/app_localizations.dart';
import 'package:music_are/core/theme/app_theme.dart';
import 'package:music_are/core/widgets/media/media_card.dart';
import 'package:music_are/core/widgets/media/media_card_metrics.dart';
import 'package:music_are/core/widgets/media/media_cover_image.dart';

void main() {
  Widget buildTestableWidget({required Widget child, double textScale = 1.0}) {
    return MaterialApp(
      theme: AppTheme.darkTheme,
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      home: MediaQuery(
        data: MediaQueryData(textScaler: TextScaler.linear(textScale)),
        child: Scaffold(body: Center(child: child)),
      ),
    );
  }

  Album buildAlbum({String name = 'Help!'}) {
    return Album(
      id: '123',
      name: name,
      artists: [
        Artist(
          id: '456',
          name: 'A Very Long Artist Name That Could Also Wrap Or Cause Issues',
          externalUri: '',
        ),
      ],
      releaseDate: '1965',
      externalUri: '',
      totalTracks: 14,
      albumType: AlbumType.album,
    );
  }

  group('MediaCard Widget Tests', () {
    testWidgets('renders Album with title and type • artist subtitle', (
      tester,
    ) async {
      await tester.pumpWidget(
        buildTestableWidget(
          child: SizedBox(
            width: MediaCardMetrics.rowCardWidth,
            height: 300.0,
            child: MediaCard(item: buildAlbum()),
          ),
        ),
      );

      expect(find.text('Help!'), findsOneWidget);
      expect(
        find.textContaining('Album • A Very Long Artist Name'),
        findsOneWidget,
      );
    });

    testWidgets('explicit width pins the card and its square cover', (
      tester,
    ) async {
      const cardWidth = 120.0;

      await tester.pumpWidget(
        buildTestableWidget(
          child: Builder(
            builder: (context) => SizedBox(
              height: MediaCardMetrics.cardHeight(context, cardWidth),
              child: MediaCard(item: buildAlbum(), width: cardWidth),
            ),
          ),
        ),
      );

      final context = tester.element(find.byType(MediaCard));
      final size = tester.getSize(find.byType(MediaCard));

      expect(size.width, cardWidth);
      expect(
        size.height,
        closeTo(cardWidth + MediaCardMetrics.textBlockHeight(context), 0.01),
      );
      expect(
        tester.getSize(find.byType(MediaCoverImage)),
        const Size(cardWidth, cardWidth),
      );
      expect(tester.takeException(), isNull);
    });

    testWidgets('renders Playlist with title and Playlist • owner subtitle', (
      tester,
    ) async {
      final playlist = Playlist(
        id: 'pl1',
        name: 'Chill Vibes',
        description: 'Relaxing music',
        externalUri: '',
        owner: User(id: 'u1', name: 'Dan', externalUri: ''),
      );

      await tester.pumpWidget(
        buildTestableWidget(
          child: SizedBox(
            width: MediaCardMetrics.rowCardWidth,
            height: 300.0,
            child: MediaCard(item: playlist),
          ),
        ),
      );

      expect(find.text('Chill Vibes'), findsOneWidget);
      expect(find.text('Playlist • Dan'), findsOneWidget);
    });

    for (final scale in [1.0, 1.3, 1.5, 2.0]) {
      testWidgets('does not overflow in a grid-sized cell at textScaler $scale',
          (tester) async {
        final album = buildAlbum(
          name: 'A Very Long Album Title That Might Span Multiple Lines And Wrap',
        );

        await tester.pumpWidget(
          buildTestableWidget(
            textScale: scale,
            child: Builder(
              builder: (context) {
                final cellHeight = MediaCardMetrics.cardHeight(context, 140.0);
                return SizedBox(
                  width: 140.0,
                  height: cellHeight,
                  child: MediaCard(item: album),
                );
              },
            ),
          ),
        );

        expect(tester.takeException(), isNull);
        expect(find.textContaining('A Very Long Album Title'), findsOneWidget);
      });
    }
  });
}
