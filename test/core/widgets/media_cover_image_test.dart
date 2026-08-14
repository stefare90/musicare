import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:gyawun_metadata_sdk/metadata/models/image.dart' as sdk;
import 'package:music_are/core/models/media_type.dart';
import 'package:music_are/core/widgets/media/media_cover_image.dart';

void main() {
  Widget buildTestableWidget({required MediaCoverImage child}) {
    return MaterialApp(
      home: Scaffold(body: Center(child: child)),
    );
  }

  group('MediaCoverImage Widget Tests', () {
    testWidgets(
      'renders default music note icon when images are null and mediaType is unknown',
      (tester) async {
        await tester.pumpWidget(
          buildTestableWidget(
            child: const MediaCoverImage(
              images: null,
              mediaType: MediaType.unknown,
            ),
          ),
        );

        expect(find.byIcon(Icons.music_note_rounded), findsOneWidget);
        expect(find.byType(CachedNetworkImage), findsNothing);
      },
    );

    testWidgets(
      'renders specific icon for passed mediaType when images list is empty',
      (tester) async {
        await tester.pumpWidget(
          buildTestableWidget(
            child: const MediaCoverImage(
              images: [],
              mediaType: MediaType.artist,
            ),
          ),
        );

        expect(find.byIcon(Icons.person_rounded), findsOneWidget);
        expect(find.byType(CachedNetworkImage), findsNothing);
      },
    );

    testWidgets('renders CachedNetworkImage when valid image URL is provided', (
      tester,
    ) async {
      await tester.pumpWidget(
        buildTestableWidget(
          child: MediaCoverImage(
            images: [sdk.Image(url: 'https://example.com/cover.jpg')],
            mediaType: MediaType.track,
          ),
        ),
      );

      expect(find.byType(CachedNetworkImage), findsOneWidget);
    });

    testWidgets(
      'selects smallest image equal or greater than requested target size',
      (tester) async {
        final variants = [
          sdk.Image(
            url: 'https://example.com/small.jpg',
            width: 250,
            height: 250,
          ),
          sdk.Image(
            url: 'https://example.com/medium.jpg',
            width: 500,
            height: 500,
          ),
          sdk.Image(
            url: 'https://example.com/large.jpg',
            width: 1200,
            height: 1200,
          ),
        ];

        await tester.pumpWidget(
          buildTestableWidget(
            child: MediaCoverImage(
              images: variants,
              mediaType: MediaType.track,
              width: 44, // Miniatura -> Seleziona la prima >= 132px (250px)
              height: 44,
            ),
          ),
        );

        final imageWidget = tester.widget<CachedNetworkImage>(
          find.byType(CachedNetworkImage),
        );
        expect(imageWidget.imageUrl, equals('https://example.com/small.jpg'));
      },
    );

    testWidgets(
      'selects largest image when width and height are null and width metadata is present',
      (tester) async {
        final variants = [
          sdk.Image(
            url: 'https://example.com/small.jpg',
            width: 250,
            height: 250,
          ),
          sdk.Image(
            url: 'https://example.com/medium.jpg',
            width: 500,
            height: 500,
          ),
          sdk.Image(
            url: 'https://example.com/large.jpg',
            width: 1200,
            height: 1200,
          ),
        ];

        await tester.pumpWidget(
          buildTestableWidget(
            child: MediaCoverImage(
              images: variants,
              mediaType: MediaType.album,
            ),
          ),
        );

        final imageWidget = tester.widget<CachedNetworkImage>(
          find.byType(CachedNetworkImage),
        );
        expect(imageWidget.imageUrl, equals('https://example.com/large.jpg'));
      },
    );

    testWidgets(
      'falls back to first image when images do not have width metadata',
      (tester) async {
        final variants = [
          sdk.Image(url: 'https://example.com/first.jpg'),
          sdk.Image(url: 'https://example.com/second.jpg'),
        ];

        await tester.pumpWidget(
          buildTestableWidget(
            child: MediaCoverImage(
              images: variants,
              mediaType: MediaType.album,
            ),
          ),
        );

        final imageWidget = tester.widget<CachedNetworkImage>(
          find.byType(CachedNetworkImage),
        );
        expect(imageWidget.imageUrl, equals('https://example.com/first.jpg'));
      },
    );

    testWidgets('wraps image in ClipRRect when borderRadius is provided', (
      tester,
    ) async {
      await tester.pumpWidget(
        buildTestableWidget(
          child: MediaCoverImage(
            images: [sdk.Image(url: 'https://example.com/cover.jpg')],
            mediaType: MediaType.track,
            borderRadius: const BorderRadius.all(Radius.circular(16.0)),
          ),
        ),
      );

      expect(find.byType(ClipRRect), findsOneWidget);
      final clipRRect = tester.widget<ClipRRect>(find.byType(ClipRRect));
      expect(
        clipRRect.borderRadius,
        equals(const BorderRadius.all(Radius.circular(16.0))),
      );
    });
  });
}
