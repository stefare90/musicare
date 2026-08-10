import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:music_are/core/models/media_item_metadata.dart';
import 'package:music_are/core/models/media_type.dart';
import 'package:music_are/core/widgets/media/sliver_media_header.dart';
import 'package:music_are/core/widgets/media/media_cover_image.dart';
import 'package:music_are/core/l10n/app_localizations.dart';

void main() {
  Widget buildTestableWidget({required SliverMediaHeader child}) {
    return MaterialApp(
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      home: Scaffold(body: CustomScrollView(slivers: [child])),
    );
  }

  group('SliverMediaHeader Widget Tests', () {
    testWidgets('renders title, subtitle, details and cover image', (
      tester,
    ) async {
      const meta = MediaItemMetadata(
        title: 'Test Title',
        mediaType: MediaType.album,
        subtitle: 'Test Subtitle',
        details: 'Test Details',
      );

      await tester.pumpWidget(
        buildTestableWidget(child: const SliverMediaHeader(meta: meta)),
      );
      await tester.pumpAndSettle();

      expect(find.text('Test Title'), findsOneWidget);
      expect(find.text('Test Subtitle'), findsOneWidget);
      expect(find.text('Test Details'), findsOneWidget);
      expect(find.byType(MediaCoverImage), findsOneWidget);
    });
  });
}
