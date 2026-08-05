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
        expect(find.byType(Image), findsNothing);
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
        expect(find.byType(Image), findsNothing);
      },
    );

    testWidgets('renders Image.network when valid image URL is provided', (
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

      expect(find.byType(Image), findsOneWidget);
    });

    testWidgets(
      'renders single image for Album even if it has 4 resolution variants',
      (tester) async {
        final albumVariants = [
          sdk.Image(url: 'https://example.com/64x64.jpg'),
          sdk.Image(url: 'https://example.com/300x300.jpg'),
          sdk.Image(url: 'https://example.com/600x600.jpg'),
          sdk.Image(url: 'https://example.com/1000x1000.jpg'),
        ];

        await tester.pumpWidget(
          buildTestableWidget(
            child: MediaCoverImage(
              images: albumVariants,
              mediaType: MediaType.album,
            ),
          ),
        );

        // Deve mostrare 1 sola immagine (non il mosaico)
        expect(find.byType(Image), findsOneWidget);
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
