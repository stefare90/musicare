import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:music_are/core/l10n/app_localizations.dart';
import 'package:music_are/features/plugin/management/presentation/cubit/plugin_manager_cubit.dart';
import 'package:music_are/features/plugin/management/presentation/cubit/plugin_manager_state.dart';
import 'package:music_are/features/plugin/metadata/presentation/cubit/user_cubit.dart';
import 'package:music_are/features/plugin/shared/presentation/cubit/plugin_session_cubit.dart';
import 'package:music_are/features/plugin/shared/data/models/plugin_auth_state.dart';
import 'package:music_are/features/plugin/shared/data/models/plugin_manifest.dart';
import 'package:music_are/features/plugin/shared/data/exceptions/plugin_exceptions.dart';
import 'package:music_are/features/plugin/shared/data/models/plugin_type.dart';
import 'package:music_are/features/settings/presentation/pages/plugin_detail_page.dart';

import '../../../../helpers/audio_source_test_helpers.dart';
import '../../../../helpers/error_presentation_test_helpers.dart';
import '../../../../helpers/metadata_plugin_test_helpers.dart';
import '../../../../helpers/plugin_session_cubit_test_helpers.dart';
import '../../../../helpers/plugin_manager_test_helpers.dart';

void main() {
  setUpAll(() {
    registerFallbackValue(testPluginManifest());
    registerFallbackValue(PluginType.metadata);
  });

  Widget buildTestableWidget({
    required PluginType type,
    PluginManagerCubit? managementCubit,
    PluginSessionCubit? pluginCubit,
    UserCubit? authCubit,
  }) {
    return MultiBlocProvider(
      providers: [
        BlocProvider<PluginSessionCubit>.value(
          value:
              pluginCubit ??
              buildTestPluginSessionCubit(
                metadata: testRuntimeLoaded(testPluginManifest()),
                audioSource: testRuntimeLoaded(testAudioSourceManifest()),
              ),
        ),
        BlocProvider<UserCubit>.value(
          value: authCubit ?? TestUserCubit(testUserState()),
        ),
        BlocProvider<PluginManagerCubit>.value(
          value:
              managementCubit ??
              buildMockPluginManagerCubit(
                state: testManagerState(
                  metadata: testPluginManifest(),
                  audioSource: testAudioSourceManifest(),
                ),
              ),
        ),
      ],
      child: MaterialApp(
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: PluginDetailPage(type: type),
      ),
    );
  }

  testWidgets('metadata detail shows version and the signed-in account', (
    tester,
  ) async {
    await tester.pumpWidget(
      buildTestableWidget(
        type: PluginType.metadata,
        pluginCubit: buildTestPluginSessionCubit(
          metadata: testRuntimeLoaded(testPluginManifest()),
          audioSource: testRuntimeLoaded(testAudioSourceManifest()),
          authStates: {
            PluginType.metadata: const PluginAuthState.signedIn('listener'),
          },
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Test Provider'), findsOneWidget);
    expect(find.text('Installed version'), findsOneWidget);
    expect(find.text('v1.0.0'), findsOneWidget);
    expect(find.text('Plugin SDK'), findsOneWidget);
    expect(find.text('Account'), findsOneWidget);
    expect(find.text('listener'), findsOneWidget);
    expect(find.text('Sign out'), findsOneWidget);
  });

  testWidgets('orders version, account and actions from top to bottom', (
    tester,
  ) async {
    await tester.binding.setSurfaceSize(const Size(800, 1200));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    await tester.pumpWidget(
      buildTestableWidget(
        type: PluginType.metadata,
        pluginCubit: buildTestPluginSessionCubit(
          metadata: testRuntimeLoaded(testPluginManifest()),
          audioSource: testRuntimeLoaded(testAudioSourceManifest()),
          authStates: {
            PluginType.metadata: const PluginAuthState.signedIn('listener'),
          },
        ),
      ),
    );
    await tester.pumpAndSettle();

    final versionY = tester.getTopLeft(find.text('Installed version')).dy;
    final accountY = tester.getTopLeft(find.text('Account')).dy;
    final actionsY = tester.getTopLeft(find.text('Actions')).dy;

    expect(versionY, lessThan(accountY));
    expect(accountY, lessThan(actionsY));
  });

  testWidgets('metadata detail signs in when signed out', (tester) async {
    var signInCalls = 0;
    await tester.pumpWidget(
      buildTestableWidget(
        type: PluginType.metadata,
        pluginCubit: buildTestPluginSessionCubit(
          metadata: testRuntimeLoaded(testPluginManifest()),
          audioSource: testRuntimeLoaded(testAudioSourceManifest()),
        )..onSignIn = (_) => signInCalls++,
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Not signed in'), findsOneWidget);

    await tester.tap(find.text('Sign in'));
    await tester.pumpAndSettle();

    expect(signInCalls, 1);
  });

  testWidgets('audio source detail shows the version without an account', (
    tester,
  ) async {
    await tester.pumpWidget(buildTestableWidget(type: PluginType.audioSource));
    await tester.pumpAndSettle();

    expect(find.text('Test Audio'), findsOneWidget);
    expect(find.text('Installed version'), findsOneWidget);
    expect(find.text('Account'), findsNothing);
    expect(find.text('Sign in'), findsNothing);
  });

  testWidgets('shows the empty state when the plugin is not configured', (
    tester,
  ) async {
    await tester.pumpWidget(
      buildTestableWidget(
        type: PluginType.metadata,
        managementCubit: buildMockPluginManagerCubit(state: testManagerState()),
        pluginCubit: buildTestPluginSessionCubit(),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Not configured'), findsOneWidget);
  });

  testWidgets('shows Update only when an update is available', (tester) async {
    final installed = testPluginManifest();
    final remote = PluginManifest(
      id: installed.id,
      packageId: installed.packageId,
      type: installed.type,
      name: installed.name,
      version: '2.0.0',
      pluginSdkVersion: installed.pluginSdkVersion,
      author: installed.author,
      description: installed.description,
    );

    await tester.pumpWidget(
      buildTestableWidget(
        type: PluginType.metadata,
        managementCubit: buildMockPluginManagerCubit(
          state: testManagerState(
            metadataSlot: testPluginSlot(
              installed: installed,
              remote: remote,
              updateAvailable: true,
            ),
            audioSource: testAudioSourceManifest(),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Actions'), findsOneWidget);
    expect(find.text('Update'), findsOneWidget);
    expect(find.text('Reinstall'), findsOneWidget);
    expect(find.text('Replace…'), findsOneWidget);
  });

  testWidgets('hides Update when the plugin is up to date', (tester) async {
    await tester.pumpWidget(buildTestableWidget(type: PluginType.metadata));
    await tester.pumpAndSettle();

    expect(find.text('Actions'), findsOneWidget);
    expect(find.text('Update'), findsNothing);
    expect(find.text('Reinstall'), findsOneWidget);
  });

  testWidgets('confirming Replace changes the plugin', (tester) async {
    final installed = testPluginManifest();
    final alternative = PluginManifest(
      id: 'other.plugin',
      packageId: 'other_plugin',
      type: 'metadata',
      name: 'Other Provider',
      version: '1.0.0',
      pluginSdkVersion: '6.0.0',
      author: 'Tester',
      description: 'Other',
    );
    final management = buildMockPluginManagerCubit(
      state: testManagerState(
        metadataSlot: testPluginSlot(installed: installed),
        audioSource: testAudioSourceManifest(),
      ),
    );
    when(
      () => management.alternatives(PluginType.metadata),
    ).thenAnswer((_) async => [alternative]);
    when(
      () => management.change(PluginType.metadata, alternative),
    ).thenAnswer((_) async {});

    await tester.pumpWidget(
      buildTestableWidget(
        type: PluginType.metadata,
        managementCubit: management,
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.text('Replace…'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Other Provider'));
    await tester.pumpAndSettle();

    expect(find.text('Replace plugin?'), findsOneWidget);
    await tester.tap(find.widgetWithText(TextButton, 'Cancel'));
    await tester.pumpAndSettle();
    verifyNever(() => management.change(PluginType.metadata, alternative));

    await tester.tap(find.text('Replace…'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Other Provider'));
    await tester.pumpAndSettle();
    await tester.tap(
      find.descendant(
        of: find.byType(AlertDialog),
        matching: find.widgetWithText(ElevatedButton, 'Replace…'),
      ),
    );
    await tester.pumpAndSettle();

    verify(() => management.change(PluginType.metadata, alternative)).called(1);
  });

  group('Check for update', () {
    late PluginManagerState current;

    setUp(registerTestErrorPresentation);

    PluginManagerCubit buildCubit({
      required PluginManagerState Function() afterCheck,
      Future<void> Function()? gate,
    }) {
      final cubit = buildMockPluginManagerCubit(
        state: testManagerState(
          metadataSlot: testPluginSlot(installed: testPluginManifest()),
        ),
      );
      final events = StreamController<PluginManagerState>.broadcast();
      addTearDown(events.close);
      current = cubit.state;
      when(() => cubit.state).thenAnswer((_) => current);
      when(() => cubit.stream).thenAnswer((_) => events.stream);
      when(
        () => cubit.refresh(
          force: true,
          fetchCatalog: any(named: 'fetchCatalog'),
        ),
      ).thenAnswer((_) async {
        if (gate != null) await gate();
        current = PluginManagerState({...current.slots, ...afterCheck().slots});
        events.add(current);
      });
      return cubit;
    }

    Future<void> tapCheck(WidgetTester tester) async {
      await tester.tap(find.text('Check for update'));
      await tester.pumpAndSettle();
    }

    testWidgets('shows a spinner while the catalog is being checked', (
      tester,
    ) async {
      final completer = Completer<void>();
      final installed = testPluginManifest();
      final cubit = buildCubit(
        gate: () => completer.future,
        afterCheck: () => testManagerState(
          metadataSlot: testPluginSlot(installed: installed, remote: installed),
        ),
      );
      await tester.pumpWidget(
        buildTestableWidget(type: PluginType.metadata, managementCubit: cubit),
      );
      await tester.pumpAndSettle();

      await tester.tap(find.text('Check for update'));
      await tester.pump();

      expect(find.byType(LinearProgressIndicator), findsOneWidget);

      completer.complete();
      await tester.pumpAndSettle();

      expect(find.byType(LinearProgressIndicator), findsNothing);
      expect(find.text("You're up to date"), findsOneWidget);
    });

    testWidgets('stacks the actions with Check for update last', (
      tester,
    ) async {
      final installed = testPluginManifest();
      final cubit = buildMockPluginManagerCubit(
        state: testManagerState(
          metadataSlot: testPluginSlot(
            installed: installed,
            remote: installed,
            updateAvailable: true,
          ),
        ),
      );
      await tester.pumpWidget(
        buildTestableWidget(type: PluginType.metadata, managementCubit: cubit),
      );
      await tester.pumpAndSettle();

      final update = tester.getTopLeft(find.text('Update')).dy;
      final reinstall = tester.getTopLeft(find.text('Reinstall')).dy;
      final replace = tester.getTopLeft(find.text('Replace…')).dy;
      final check = tester.getTopLeft(find.text('Check for update')).dy;

      expect(update, lessThan(reinstall));
      expect(reinstall, lessThan(replace));
      expect(replace, lessThan(check));
    });

    testWidgets('reports an up-to-date plugin', (tester) async {
      final installed = testPluginManifest();
      final cubit = buildCubit(
        afterCheck: () => testManagerState(
          metadataSlot: testPluginSlot(installed: installed, remote: installed),
        ),
      );
      await tester.pumpWidget(
        buildTestableWidget(type: PluginType.metadata, managementCubit: cubit),
      );
      await tester.pumpAndSettle();

      await tapCheck(tester);

      expect(find.text("You're up to date"), findsOneWidget);
      expect(find.text('Update'), findsNothing);
    });

    testWidgets('reports the new version and reveals Update', (tester) async {
      final installed = testPluginManifest();
      final remote = PluginManifest(
        id: installed.id,
        packageId: installed.packageId,
        type: installed.type,
        name: installed.name,
        version: '2.0.0',
        pluginSdkVersion: installed.pluginSdkVersion,
        author: installed.author,
        description: installed.description,
      );
      final cubit = buildCubit(
        afterCheck: () => testManagerState(
          metadataSlot: testPluginSlot(
            installed: installed,
            remote: remote,
            updateAvailable: true,
          ),
        ),
      );
      await tester.pumpWidget(
        buildTestableWidget(type: PluginType.metadata, managementCubit: cubit),
      );
      await tester.pumpAndSettle();

      await tapCheck(tester);

      expect(find.text('v2.0.0 is available'), findsOneWidget);
      expect(find.text('Update'), findsOneWidget);
    });

    testWidgets('reports a plugin with no published release', (tester) async {
      final cubit = buildCubit(
        afterCheck: () => testManagerState(
          metadataSlot: testPluginSlot(installed: testPluginManifest()),
        ),
      );
      await tester.pumpWidget(
        buildTestableWidget(type: PluginType.metadata, managementCubit: cubit),
      );
      await tester.pumpAndSettle();

      await tapCheck(tester);

      expect(find.text('No published release found'), findsOneWidget);
    });

    testWidgets('reports a failed check', (tester) async {
      final installed = testPluginManifest();
      final cubit = buildCubit(
        afterCheck: () => testManagerState(
          metadataSlot: testPluginSlot(
            installed: installed,
            error: PluginSearchException(403),
          ),
        ),
      );

      await tester.pumpWidget(
        buildTestableWidget(type: PluginType.metadata, managementCubit: cubit),
      );
      await tester.pumpAndSettle();

      await tapCheck(tester);

      // A 403 is the exhausted quota, not a generic network failure.
      expect(
        find.text('The provider is limiting requests. Please try again shortly.'),
        findsOneWidget,
      );
    });
  });
}
