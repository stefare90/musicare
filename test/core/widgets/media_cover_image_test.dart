import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:music_are/core/widgets/media_cover_image.dart';

void main() {
  Widget buildTestableWidget({required MediaCoverImage child}) {
    return MaterialApp(
      home: Scaffold(body: Center(child: child)),
    );
  }

  group('MediaCoverImage Widget Tests', () {
    testWidgets('renders placeholder icon when imageUrl is null', (
      tester,
    ) async {
      await tester.pumpWidget(
        buildTestableWidget(
          child: const MediaCoverImage(
            imageUrl: null,
            fallbackIcon: Icons.album_rounded,
          ),
        ),
      );

      expect(find.byIcon(Icons.album_rounded), findsOneWidget);
      expect(find.byType(Image), findsNothing);
    });

    testWidgets('renders placeholder icon when imageUrl is empty string', (
      tester,
    ) async {
      await tester.pumpWidget(
        buildTestableWidget(
          child: const MediaCoverImage(
            imageUrl: '',
            fallbackIcon: Icons.playlist_play_rounded,
          ),
        ),
      );

      expect(find.byIcon(Icons.playlist_play_rounded), findsOneWidget);
      expect(find.byType(Image), findsNothing);
    });

    testWidgets('renders Image.network when imageUrl is provided', (
      tester,
    ) async {
      await tester.pumpWidget(
        buildTestableWidget(
          child: const MediaCoverImage(
            imageUrl: 'https://example.com/cover.jpg',
            fallbackIcon: Icons.music_note_rounded,
          ),
        ),
      );

      expect(find.byType(Image), findsOneWidget);
    });

    testWidgets('wraps image in ClipRRect when borderRadius is provided', (
      tester,
    ) async {
      await tester.pumpWidget(
        buildTestableWidget(
          child: const MediaCoverImage(
            imageUrl: 'https://example.com/cover.jpg',
            borderRadius: BorderRadius.all(Radius.circular(16.0)),
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
