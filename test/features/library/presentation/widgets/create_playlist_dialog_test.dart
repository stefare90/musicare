import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:music_are/core/l10n/app_localizations.dart';
import 'package:music_are/features/library/presentation/widgets/create_playlist_dialog.dart';

void main() {
  testWidgets('collects name, description and visibility', (tester) async {
    CreatePlaylistResult? result;

    await tester.pumpWidget(
      MaterialApp(
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: Builder(
          builder: (context) => ElevatedButton(
            onPressed: () async {
              result = await CreatePlaylistDialog.show(context);
            },
            child: const Text('open'),
          ),
        ),
      ),
    );

    await tester.tap(find.text('open'));
    await tester.pumpAndSettle();

    expect(find.text('Name'), findsOneWidget);
    expect(find.text('Description'), findsOneWidget);
    expect(find.text('Public'), findsOneWidget);

    // The action is disabled until a name is provided.
    final createButton = tester.widget<ElevatedButton>(
      find.widgetWithText(ElevatedButton, 'Create'),
    );
    expect(createButton.onPressed, isNull);

    await tester.enterText(find.byType(TextField).first, 'My playlist');
    await tester.pump();
    await tester.tap(find.widgetWithText(ElevatedButton, 'Create'));
    await tester.pumpAndSettle();

    expect(result?.name, 'My playlist');
    expect(result?.description, isNull);
    expect(result?.isPublic, isFalse);
  });
}
