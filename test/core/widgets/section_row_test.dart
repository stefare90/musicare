import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:gyawun_metadata_sdk/metadata/models/album.dart';
import 'package:music_are/core/l10n/app_localizations.dart';
import 'package:music_are/core/widgets/media/section_row.dart';

void main() {
  Widget buildTestableWidget({required SectionRow child}) {
    return MaterialApp(
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      home: Scaffold(body: child),
    );
  }

  group('SectionRow Widget Tests', () {
    final testAlbum = Album(
      id: 'al1',
      name: 'Abbey Road',
      artists: [],
      releaseDate: '1969',
      externalUri: '',
      totalTracks: 17,
      albumType: AlbumType.album,
    );

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
  });
}
