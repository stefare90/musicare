import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:music_are/core/l10n/app_localizations.dart';
import 'package:music_are/features/library/presentation/widgets/create_playlist_dialog.dart';

/// Pumps a host that opens [CreatePlaylistDialog] and reports its result.
///
/// [keyboardHeight] is injected as the bottom view inset, because widget tests
/// never show a real keyboard but the dialog still has to survive it.
Widget buildHost({
  required void Function(CreatePlaylistResult?) onResult,
  double keyboardHeight = 0,
  double textScaler = 1,
}) {
  return MaterialApp(
    localizationsDelegates: AppLocalizations.localizationsDelegates,
    supportedLocales: AppLocalizations.supportedLocales,
    builder: (context, child) => MediaQuery(
      data: MediaQuery.of(context).copyWith(
        viewInsets: EdgeInsets.only(bottom: keyboardHeight),
        textScaler: TextScaler.linear(textScaler),
      ),
      child: child!,
    ),
    home: Builder(
      builder: (context) => Scaffold(
        body: ElevatedButton(
          onPressed: () async {
            onResult(await CreatePlaylistDialog.show(context));
          },
          child: const Text('open'),
        ),
      ),
    ),
  );
}

void useLandscape(WidgetTester tester) {
  tester.view.devicePixelRatio = 1;
  tester.view.physicalSize = const Size(960, 432);
  addTearDown(tester.view.reset);
}

void main() {
  testWidgets('collects name, description and visibility', (tester) async {
    CreatePlaylistResult? result;

    await tester.pumpWidget(
      buildHost(onResult: (value) => result = value),
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

  testWidgets('fits in landscape with the keyboard open', (tester) async {
    useLandscape(tester);
    CreatePlaylistResult? result;

    await tester.pumpWidget(
      buildHost(keyboardHeight: 180, onResult: (value) => result = value),
    );

    await tester.tap(find.text('open'));
    await tester.pumpAndSettle();

    expect(tester.takeException(), isNull);
    expect(find.text('Name'), findsOneWidget);

    await tester.enterText(find.byType(TextField).first, 'Landscape list');
    await tester.pump();
    await tester.tap(find.widgetWithText(ElevatedButton, 'Create'));
    await tester.pumpAndSettle();

    expect(result?.name, 'Landscape list');
  });

  testWidgets('fits in landscape with a large text scale', (tester) async {
    useLandscape(tester);

    await tester.pumpWidget(
      buildHost(
        keyboardHeight: 180,
        textScaler: 1.3,
        onResult: (_) {},
      ),
    );

    await tester.tap(find.text('open'));
    await tester.pumpAndSettle();

    expect(tester.takeException(), isNull);
    expect(find.text('Name'), findsOneWidget);
  });
}
