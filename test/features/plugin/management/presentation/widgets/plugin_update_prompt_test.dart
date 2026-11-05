import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:music_are/core/l10n/app_localizations.dart';
import 'package:music_are/features/plugin/management/presentation/cubit/plugin_manager_state.dart';
import 'package:music_are/features/plugin/management/presentation/widgets/plugin_update_prompt.dart';
import 'package:music_are/features/plugin/shared/data/models/plugin_manifest.dart';
import 'package:music_are/features/plugin/shared/data/models/plugin_type.dart';

import '../../../../../helpers/audio_source_test_helpers.dart';
import '../../../../../helpers/metadata_plugin_test_helpers.dart';
import '../../../../../helpers/plugin_manager_test_helpers.dart';

PluginManifest _newer(PluginManifest base, String version) => PluginManifest(
  id: base.id,
  packageId: base.packageId,
  type: base.type,
  name: base.name,
  version: version,
  pluginSdkVersion: base.pluginSdkVersion,
  author: base.author,
  description: base.description,
);

void main() {
  final installed = testPluginManifest();
  final remote = _newer(installed, '2.0.0');
  final audioInstalled = testAudioSourceManifest();
  final audioRemote = _newer(audioInstalled, '2.0.0');

  late MockPluginManagerCubit cubit;
  late PluginManagerState current;

  PluginManagerState updatesState() => testManagerState(
    metadataSlot: testPluginSlot(
      installed: installed,
      remote: remote,
      updateAvailable: true,
    ),
    audioSourceSlot: testPluginSlot(
      installed: audioInstalled,
      remote: audioRemote,
      updateAvailable: true,
    ),
  );

  setUpAll(() {
    registerFallbackValue(PluginType.metadata);
  });

  setUp(() {
    cubit = MockPluginManagerCubit();
    current = testManagerState();
    when(() => cubit.state).thenAnswer((_) => current);
    when(() => cubit.stream).thenAnswer((_) => const Stream.empty());
    when(
      () => cubit.refresh(
        force: any(named: 'force'),
        fetchCatalog: any(named: 'fetchCatalog'),
      ),
    ).thenAnswer((_) => Future<void>.value());
    when(() => cubit.update(any())).thenAnswer((_) => Future<void>.value());
  });

  /// Only the tests that must see the dialog stub the check this way.
  void checkFindsUpdates() {
    when(
      () => cubit.refresh(
        force: any(named: 'force'),
        fetchCatalog: any(named: 'fetchCatalog'),
      ),
    ).thenAnswer((_) {
      current = updatesState();
      return Future<void>.value();
    });
  }

  Widget build(void Function(BuildContext) capture) {
    return MaterialApp(
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      home: Builder(
        builder: (context) {
          capture(context);
          return const Scaffold(body: Text('home'));
        },
      ),
    );
  }

  testWidgets('does nothing when no update is available', (tester) async {
    late BuildContext context;
    await tester.pumpWidget(
      build((c) {
        context = c;
      }),
    );

    await PluginUpdatePrompt.runStartupCheck(context, cubit);
    await tester.pumpAndSettle();

    verify(() => cubit.refresh(fetchCatalog: true, force: false)).called(1);
    expect(find.byType(AlertDialog), findsNothing);
    verifyNever(() => cubit.update(any()));
  });

  testWidgets('lists every available update and updates them on confirm', (
    tester,
  ) async {
    checkFindsUpdates();
    final updated = <PluginType>[];
    when(() => cubit.update(any())).thenAnswer((invocation) {
      updated.add(invocation.positionalArguments.first as PluginType);
      return Future<void>.value();
    });
    late BuildContext context;
    await tester.pumpWidget(
      build((c) {
        context = c;
      }),
    );

    final flow = PluginUpdatePrompt.runStartupCheck(context, cubit);
    await tester.pumpAndSettle();

    expect(find.text('Plugin updates available'), findsOneWidget);
    // One line per slot, in PluginType order.
    expect(
      find.text('Metadata 1.0.0 → 2.0.0\nAudio source 1.0.0 → 2.0.0'),
      findsOneWidget,
    );
    expect(find.text('Not now'), findsOneWidget);

    await tester.tap(find.text('Update now'));
    await tester.pumpAndSettle();
    await flow;

    expect(updated, [PluginType.metadata, PluginType.audioSource]);
    expect(find.text('Plugins updated.'), findsOneWidget);
  });

  testWidgets('Not now keeps the plugins untouched', (tester) async {
    checkFindsUpdates();
    late BuildContext context;
    await tester.pumpWidget(
      build((c) {
        context = c;
      }),
    );

    final flow = PluginUpdatePrompt.runStartupCheck(context, cubit);
    await tester.pumpAndSettle();
    await tester.tap(find.text('Not now'));
    await tester.pumpAndSettle();
    await flow;

    expect(find.byType(AlertDialog), findsNothing);
    verifyNever(() => cubit.update(any()));
  });

  testWidgets('a failing update does not stop the others', (tester) async {
    checkFindsUpdates();
    final updated = <PluginType>[];
    when(() => cubit.update(any())).thenAnswer((invocation) {
      final type = invocation.positionalArguments.first as PluginType;
      updated.add(type);
      current = PluginManagerState({
        ...current.slots,
        type: current.slot(type).copyWith(error: Exception('download failed')),
      });
      return Future<void>.value();
    });
    late BuildContext context;
    await tester.pumpWidget(
      build((c) {
        context = c;
      }),
    );

    final flow = PluginUpdatePrompt.runStartupCheck(context, cubit);
    await tester.pumpAndSettle();
    await tester.tap(find.text('Update now'));
    await tester.pumpAndSettle();
    await flow;

    expect(updated, [PluginType.metadata, PluginType.audioSource]);
    expect(find.text('Updated 0 of 2 plugins.'), findsOneWidget);
  });

  testWidgets('an incompatible plugin never reaches the dialog', (
    tester,
  ) async {
    when(
      () => cubit.refresh(
        force: any(named: 'force'),
        fetchCatalog: any(named: 'fetchCatalog'),
      ),
    ).thenAnswer((_) {
      current = testManagerState(
        metadataSlot: testPluginSlot(
          installed: installed,
          remote: remote,
          updateAvailable: true,
          incompatible: true,
        ),
      );
      return Future<void>.value();
    });
    late BuildContext context;
    await tester.pumpWidget(
      build((c) {
        context = c;
      }),
    );

    await PluginUpdatePrompt.runStartupCheck(context, cubit);
    await tester.pumpAndSettle();

    expect(find.byType(AlertDialog), findsNothing);
  });
}
