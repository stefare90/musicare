import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:music_are/core/models/media_type.dart';
import 'package:music_are/core/widgets/media/cover_fallback.dart';

void main() {
  Widget buildTestableWidget(MediaType type) => MaterialApp(
    home: Scaffold(
      body: SizedBox(
        width: 200,
        height: 200,
        child: CoverFallback(mediaType: type),
      ),
    ),
  );

  testWidgets('draws the icon of the media type', (tester) async {
    await tester.pumpWidget(buildTestableWidget(MediaType.album));
    await tester.pump();

    expect(find.byIcon(Icons.album_rounded), findsOneWidget);
  });

  testWidgets('uses the media type icon for playlists too', (tester) async {
    await tester.pumpWidget(buildTestableWidget(MediaType.playlist));
    await tester.pump();

    expect(find.byIcon(Icons.playlist_play_rounded), findsOneWidget);
  });
}
