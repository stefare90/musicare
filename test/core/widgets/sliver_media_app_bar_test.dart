import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:music_are/core/l10n/app_localizations.dart'; // <--- Importazione aggiunta
import 'package:music_are/core/widgets/media/sliver_media_app_bar.dart';

void main() {
  Widget buildTestableWidget({required SliverMediaAppBar child}) {
    return MaterialApp(
      localizationsDelegates:
          AppLocalizations.localizationsDelegates, // <--- Aggiunto
      supportedLocales: AppLocalizations.supportedLocales, // <--- Aggiunto
      home: Scaffold(body: CustomScrollView(slivers: [child])),
    );
  }

  group('SliverMediaAppBar Widget Tests', () {
    testWidgets('renders title and action icons', (tester) async {
      bool isSavedTapped = false;

      await tester.pumpWidget(
        buildTestableWidget(
          child: SliverMediaAppBar(
            title: 'My Playlist',
            isSaved: true,
            onSaveTap: () => isSavedTapped = true,
          ),
        ),
      );

      expect(find.text('My Playlist'), findsOneWidget);
      expect(find.byIcon(Icons.favorite_rounded), findsOneWidget);

      await tester.tap(find.byIcon(Icons.favorite_rounded));
      await tester.pumpAndSettle();

      expect(isSavedTapped, isTrue);
    });
  });
}
