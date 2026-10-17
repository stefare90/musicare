import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:music_are/core/models/media_type.dart';
import 'package:music_are/core/widgets/media/cover_backdrop.dart';
import 'package:music_are/core/widgets/media/media_cover_image.dart';
import 'package:music_are/core/widgets/skeletons/shimmer_box.dart';
import 'package:musicare_metadata_host_sdk/metadata/models/image.dart' as sdk;

void main() {
  const image = sdk.Image(
    url: 'https://example.com/cover.jpg',
    width: 500,
    height: 500,
  );

  Widget buildTestableWidget({List<sdk.Image> images = const [image]}) {
    return MaterialApp(
      home: Scaffold(
        body: SizedBox(
          width: 400,
          height: 400,
          child: CoverBackdrop(
            images: images,
            mediaType: MediaType.album,
            haloCenter: Alignment.center,
            haloRadius: 0.5,
          ),
        ),
      ),
    );
  }

  testWidgets('blurs the cover and fades it into the background', (
    tester,
  ) async {
    await tester.pumpWidget(buildTestableWidget());
    await tester.pump();

    expect(find.byType(ImageFiltered), findsOneWidget);
    expect(find.byType(MediaCoverImage), findsOneWidget);
    // No shimmer behind: the backdrop only appears once the image is ready.
    expect(find.byType(ShimmerBox), findsNothing);
  });

  testWidgets('blurs the default placeholder when there is no artwork', (
    tester,
  ) async {
    await tester.pumpWidget(buildTestableWidget(images: const []));
    await tester.pump();

    expect(find.byType(ImageFiltered), findsOneWidget);
    expect(find.byType(MediaCoverImage), findsOneWidget);
  });
}
