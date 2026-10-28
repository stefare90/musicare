import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:music_are/core/l10n/app_localizations.dart';
import 'package:music_are/features/plugin/management/presentation/cubit/plugin_manager_cubit.dart';
import 'package:music_are/features/plugin/metadata/presentation/cubit/user_cubit.dart';
import 'package:music_are/features/plugin/presentation/cubit/plugin_session_cubit.dart';
import 'package:music_are/features/plugin/shared/data/models/plugin_auth_state.dart';
import 'package:music_are/features/plugin/shared/data/models/plugin_manifest.dart';
import 'package:music_are/features/plugin/shared/data/models/plugin_type.dart';
import 'package:music_are/features/settings/presentation/pages/plugin_detail_page.dart';

import '../../../../helpers/audio_source_test_helpers.dart';
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
}
