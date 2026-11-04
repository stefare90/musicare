import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:music_are/core/l10n/app_localizations.dart';
import 'package:music_are/features/settings/presentation/pages/app_update_page.dart';
import 'package:music_are/features/update/data/exceptions/app_update_failures.dart';
import 'package:music_are/features/update/data/models/app_update.dart';
import 'package:music_are/features/update/data/models/installed_app.dart';
import 'package:music_are/features/update/presentation/cubit/app_update_cubit.dart';
import 'package:music_are/features/update/presentation/cubit/app_update_state.dart';

import '../../../../helpers/error_presentation_test_helpers.dart';

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

  setUpAll(registerTestErrorPresentation);

  setUp(() {
    cubit = MockAppUpdateCubit();
    when(() => cubit.stream).thenAnswer((_) => const Stream.empty());
    when(() => cubit.check()).thenAnswer((_) async {});
    when(() => cubit.updateNow()).thenAnswer((_) async {});
    when(() => cubit.cancelDownload()).thenReturn(null);
  });

  Widget build(AppUpdateState state) {
    when(() => cubit.state).thenReturn(state);
    return BlocProvider<AppUpdateCubit>.value(
      value: cubit,
      child: MaterialApp(
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: const AppUpdatePage(),
      ),
    );
  }

  testWidgets('idle shows the app version and offers a check', (tester) async {
    await tester.pumpWidget(build(const AppUpdateState.idle(installed)));

    expect(find.text('App version'), findsOneWidget);
    expect(find.text('MusicAre'), findsOneWidget);
    expect(find.text('By stefare'), findsOneWidget);
    expect(find.text('Version'), findsOneWidget);
    expect(find.text('Installed version'), findsOneWidget);
    expect(find.text('v1.0.1 (3)'), findsOneWidget);
    expect(find.text('Status'), findsOneWidget);
    expect(find.text('Actions'), findsOneWidget);
    expect(find.text('Not checked yet'), findsOneWidget);

    await tester.tap(find.text('Check for update'));
    verify(() => cubit.check()).called(1);
  });

  testWidgets('up to date state', (tester) async {
    await tester.pumpWidget(build(const AppUpdateState.upToDate(installed)));

    expect(find.text("You're up to date"), findsOneWidget);
    expect(find.text('Check for update'), findsOneWidget);
  });

  testWidgets('available state offers the update', (tester) async {
    await tester.pumpWidget(build(AppUpdateState.available(installed, update)));

    expect(find.text('Version 1.0.2 is available (51 MB).'), findsOneWidget);
    await tester.tap(find.widgetWithText(FilledButton, 'Update'));
    verify(() => cubit.updateNow()).called(1);
  });

  testWidgets('downloading state shows progress and a cancel action', (
    tester,
  ) async {
    await tester.pumpWidget(
      build(
        AppUpdateState.downloading(
          installed,
          update,
          receivedBytes: update.apkSize ~/ 4,
          totalBytes: update.apkSize,
        ),
      ),
    );

    expect(find.text('Downloading 25%'), findsOneWidget);
    expect(find.text('13 of 51 MB'), findsOneWidget);
    expect(find.byType(LinearProgressIndicator), findsOneWidget);
    final button = tester.widget<FilledButton>(
      find.widgetWithText(FilledButton, 'Update'),
    );
    expect(button.onPressed, isNull);

    await tester.tap(find.text('Cancel'));
    verify(() => cubit.cancelDownload()).called(1);
  });

  testWidgets('installing state disables the action', (tester) async {
    await tester.pumpWidget(
      build(AppUpdateState.installing(installed, update)),
    );

    expect(find.text('Opening the installer…'), findsOneWidget);
    final button = tester.widget<FilledButton>(
      find.widgetWithText(FilledButton, 'Update'),
    );
    expect(button.onPressed, isNull);
  });

  testWidgets('a failed download shows the error and offers a retry', (
    tester,
  ) async {
    await tester.pumpWidget(
      build(
        AppUpdateState.failed(
          const UpdateCorrupted(),
          installed: installed,
          update: update,
        ),
      ),
    );

    expect(find.text('The downloaded file is corrupted.'), findsOneWidget);
    await tester.tap(find.widgetWithText(FilledButton, 'Update'));
    verify(() => cubit.updateNow()).called(1);
  });

  testWidgets('a failed check offers another check', (tester) async {
    await tester.pumpWidget(
      build(
        const AppUpdateState.failed(UpdateCheckFailed(), installed: installed),
      ),
    );

    expect(find.text("Couldn't check for updates."), findsOneWidget);
    await tester.tap(find.text('Check for update'));
    verify(() => cubit.check()).called(1);
  });
}
