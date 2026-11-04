import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:music_are/core/l10n/app_localizations.dart';
import 'package:music_are/core/router/app_router.dart';
import 'package:music_are/features/update/data/models/app_update.dart';
import 'package:music_are/features/update/data/models/installed_app.dart';
import 'package:music_are/features/update/presentation/cubit/app_update_cubit.dart';
import 'package:music_are/features/update/presentation/cubit/app_update_state.dart';
import 'package:music_are/features/update/presentation/widgets/app_update_prompt.dart';

class MockAppUpdateCubit extends Mock implements AppUpdateCubit {}

const installed = InstalledApp(
  packageName: 'com.musicare.app',
  versionName: '1.0.1',
  versionCode: 3,
);

final update = AppUpdate(
  versionName: '1.0.2',
  versionCode: 4,
  apkUri: Uri.parse('https://example.com/MusicAre-1.0.2.apk'),
  apkSize: 53477376,
  sha256: 'a' * 64,
);

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late MockAppUpdateCubit cubit;
  late AppUpdateState current;

  setUp(() {
    cubit = MockAppUpdateCubit();
    current = const AppUpdateState.idle(installed);
    when(() => cubit.state).thenAnswer((_) => current);
    when(() => cubit.check(silent: any(named: 'silent'))).thenAnswer((_) async {
      current = AppUpdateState.available(installed, update);
    });
    when(() => cubit.updateNow()).thenAnswer((_) async {});
  });

  Widget build() {
    return MaterialApp(
      navigatorKey: rootNavigatorKey,
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      home: const Scaffold(body: Text('home')),
    );
  }

  testWidgets('shows the dialog when the check finds an update', (
    tester,
  ) async {
    await tester.pumpWidget(build());

    unawaited(AppUpdatePrompt.runStartupCheck(cubit));
    await tester.pumpAndSettle();

    verify(() => cubit.check(silent: true)).called(1);
    expect(find.text('Update available'), findsOneWidget);
    expect(
      find.text("Version 1.0.2 (51 MB) — you're on 1.0.1."),
      findsOneWidget,
    );
    expect(find.text('Not now'), findsOneWidget);
    expect(find.text('Update'), findsOneWidget);
  });

  testWidgets('Not now dismisses the dialog without downloading', (
    tester,
  ) async {
    await tester.pumpWidget(build());

    final flow = AppUpdatePrompt.runStartupCheck(cubit);
    await tester.pumpAndSettle();
    await tester.tap(find.text('Not now'));
    await tester.pumpAndSettle();
    await flow;

    expect(find.text('Update available'), findsNothing);
    verifyNever(() => cubit.updateNow());
  });

  testWidgets('Update starts the download and points at Settings', (
    tester,
  ) async {
    await tester.pumpWidget(build());

    final flow = AppUpdatePrompt.runStartupCheck(cubit);
    await tester.pumpAndSettle();
    await tester.tap(find.text('Update'));
    await tester.pumpAndSettle();
    await flow;

    verify(() => cubit.updateNow()).called(1);
    expect(
      find.text('Downloading — see Settings → App version'),
      findsOneWidget,
    );
  });

  testWidgets('does nothing when the check finds no update', (tester) async {
    when(() => cubit.check(silent: true)).thenAnswer((_) async {});
    current = const AppUpdateState.upToDate(installed);
    await tester.pumpWidget(build());

    await AppUpdatePrompt.runStartupCheck(cubit);
    await tester.pumpAndSettle();

    expect(find.text('Update available'), findsNothing);
    verifyNever(() => cubit.updateNow());
  });
}
