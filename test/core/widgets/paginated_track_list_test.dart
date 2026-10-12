import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:musicare_metadata_host_sdk/musicare_metadata_host_sdk.dart';
import 'package:music_are/core/l10n/app_localizations.dart';
import 'package:music_are/core/theme/app_theme.dart';
import 'package:music_are/core/widgets/media/paginated_track_list.dart';
import 'package:music_are/core/widgets/skeletons/skeleton_track_list.dart';

void main() {
  Widget buildTestableWidget({required PaginatedTrackList child}) {
    return MaterialApp(
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      theme: AppTheme.darkTheme,
      home: Scaffold(body: child),
    );
  }

  group('PaginatedTrackList Widget Tests', () {
    final testTrack = Track(
      id: 't1',
      name: 'Come Together',
      externalUri: '',
      artists: [Artist(id: 'a1', name: 'The Beatles', externalUri: '')],
      album: const Album(
        id: 'al1',
        name: 'Abbey Road',
        artists: [],
        releaseDate: '1969',
        externalUri: '',
        totalTracks: 1,
        albumType: AlbumType.album,
      ),
      durationMs: 259000,
    );

    testWidgets('shows a skeleton row instead of a spinner while loading more',
        (tester) async {
      await tester.pumpWidget(
        buildTestableWidget(
          child: PaginatedTrackList(
            tracks: [testTrack],
            isLoadingMore: true,
          ),
        ),
      );

      expect(find.byType(SkeletonTrackList), findsOneWidget);
      expect(find.byType(CircularProgressIndicator), findsNothing);
    });

    testWidgets('wraps rows in a Dismissible only when removal is wired',
        (tester) async {
      await tester.pumpWidget(
        buildTestableWidget(
          child: PaginatedTrackList(tracks: [testTrack]),
        ),
      );
      expect(find.byType(Dismissible), findsNothing);

      await tester.pumpWidget(
        buildTestableWidget(
          child: PaginatedTrackList(
            tracks: [testTrack],
            onTrackDismissed: (_) {},
          ),
        ),
      );
      expect(find.byType(Dismissible), findsOneWidget);
    });
  });
}
