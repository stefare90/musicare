import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:mocktail/mocktail.dart';
import 'package:music_are/core/l10n/app_localizations.dart';
import 'package:music_are/features/plugin/data/models/plugin_manifest.dart';
import 'package:music_are/features/plugin/presentation/cubit/plugin_cubit.dart';
import 'package:music_are/features/plugin/presentation/cubit/plugin_state.dart';
import 'package:music_are/features/plugin/presentation/pages/plugin_update_page.dart';
import 'package:music_are/features/plugin/presentation/widgets/plugin_discovery_widget.dart';
import 'package:music_are/features/plugin/data/services/plugin_discovery_service.dart';
import 'package:get_it/get_it.dart';

class MockPluginCubit extends Mock implements PluginCubit {}

class MockPluginDiscoveryService extends Mock
    implements PluginDiscoveryService {}

void main() {
  late MockPluginCubit mockPluginCubit;
  late MockPluginDiscoveryService mockDiscoveryService;

  setUp(() async {
    final sl = GetIt.instance;
    await sl.reset();

    mockPluginCubit = MockPluginCubit();
    mockDiscoveryService = MockPluginDiscoveryService();

    sl.registerLazySingleton<PluginDiscoveryService>(
      () => mockDiscoveryService,
    );
  });

  Widget buildTestableWidget() {
    return MaterialApp(
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      home: BlocProvider<PluginCubit>.value(
        value: mockPluginCubit,
        child: const PluginUpdatePage(),
      ),
    );
  }

  testWidgets('renders obsolete manifest warning and discovery widget', (
    tester,
  ) async {
    when(() => mockPluginCubit.stream).thenAnswer((_) => const Stream.empty());

    final obsoleteManifest = PluginManifest(
      id: 'org.test',
      packageId: 'test_pkg',
      type: 'metadata',
      name: 'Test Plugin',
      version: '1.0.0',
      pluginSdkVersion: '1.0.0',
      author: 'Tester',
      description: 'Desc',
    );

    when(
      () => mockPluginCubit.state,
    ).thenReturn(PluginIncompatibleState(obsoleteManifest));
    when(
      () => mockDiscoveryService.fetchCommunityPlugins(),
    ).thenAnswer((_) async => []);

    await tester.pumpWidget(buildTestableWidget());
    await tester.pumpAndSettle();

    expect(find.text('Action Required'), findsOneWidget);
    expect(find.text('Obsolete Provider'), findsOneWidget);
    expect(find.text('Test Plugin'), findsOneWidget);
    expect(find.text('Installed version: v1.0.0'), findsOneWidget);
    expect(
      find.text(
        'This provider is no longer compatible with the current version of MusicAre and must be updated to continue.',
      ),
      findsOneWidget,
    );
    expect(find.byType(PluginDiscoveryWidget), findsOneWidget);
  });
}
