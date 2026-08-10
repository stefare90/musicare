import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:music_are/core/l10n/app_localizations.dart';
import 'package:music_are/core/models/media_type.dart';
import 'package:music_are/core/utils/media_type_localizer.dart';

void main() {
  testWidgets('MediaTypeLocalizer translates correctly', (tester) async {
    late BuildContext ctx;
    await tester.pumpWidget(
      MaterialApp(
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: Builder(
          builder: (context) {
            ctx = context;
            return const SizedBox.shrink();
          },
        ),
      ),
    );

    expect(MediaType.playlist.toLocalizedString(ctx), equals('Playlist'));
    expect(MediaType.album.toLocalizedString(ctx), equals('Album'));
    expect(MediaType.single.toLocalizedString(ctx), equals('Single'));
    expect(MediaType.compilation.toLocalizedString(ctx), equals('Compilation'));
    expect(MediaType.track.toLocalizedString(ctx), equals('Track'));
    expect(MediaType.artist.toLocalizedString(ctx), equals('Artist'));
    expect(MediaType.unknown.toLocalizedString(ctx), equals(''));
  });
}
