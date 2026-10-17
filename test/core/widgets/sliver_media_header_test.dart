import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:music_are/core/models/media_item_metadata.dart';
import 'package:music_are/core/models/media_type.dart';
import 'package:music_are/core/widgets/media/sliver_media_header.dart';
import 'package:music_are/core/widgets/media/media_cover_image.dart';
import 'package:music_are/core/l10n/app_localizations.dart';
import 'package:musicare_metadata_host_sdk/metadata/models/image.dart' as sdk;

void main() {
  Widget buildTestableWidget({required SliverMediaHeader child}) {
    return MaterialApp(
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      home: Scaffold(body: CustomScrollView(slivers: [child])),
    );
  }

  const image = sdk.Image(url: 'https://example.com/cover.jpg');

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
      // Cover + blurred placeholder backdrop (no artwork here).
      expect(find.byType(MediaCoverImage), findsNWidgets(2));
      expect(find.byType(ImageFiltered), findsOneWidget);
    });

    testWidgets('blurs the cover behind an album header with images', (
      tester,
    ) async {
      const meta = MediaItemMetadata(
        title: 'Test Title',
        mediaType: MediaType.album,
        subtitle: 'Test Subtitle',
        images: [image],
      );

      await tester.pumpWidget(
        buildTestableWidget(child: const SliverMediaHeader(meta: meta)),
      );
      await tester.pump();

      expect(find.byType(ImageFiltered), findsOneWidget);
      expect(find.byType(MediaCoverImage), findsNWidgets(2));
      // The backdrop must stay full-bleed, not shrink to the cover target size.
      expect(
        tester.getSize(find.byType(ImageFiltered)).width,
        greaterThan(300),
      );
    });

    testWidgets('renders the artist as a full-width faded photo', (
      tester,
    ) async {
      const meta = MediaItemMetadata(
        title: 'Test Artist',
        mediaType: MediaType.artist,
        subtitle: 'Test Subtitle',
        images: [image],
      );

      await tester.pumpWidget(
        buildTestableWidget(child: const SliverMediaHeader(meta: meta)),
      );
      await tester.pump();

      expect(find.byType(ImageFiltered), findsNothing);
      expect(find.byType(MediaCoverImage), findsOneWidget);
      expect(find.byType(ShaderMask), findsOneWidget);
      expect(find.text('Test Artist'), findsOneWidget);
      expect(tester.getSize(find.byType(ShaderMask)).width, greaterThan(300));
    });
  });
}
