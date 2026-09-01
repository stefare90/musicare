import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get_it/get_it.dart';
import 'package:mocktail/mocktail.dart';
import 'package:music_are/core/l10n/app_localizations.dart';
import 'package:music_are/features/plugin/discovery/data/services/plugin_discovery_service.dart';
import 'package:music_are/features/plugin/discovery/presentation/widgets/plugin_discovery_widget.dart';
import 'package:music_are/features/plugin/metadata/presentation/cubit/metadata_plugin_cubit.dart';
import 'package:music_are/features/plugin/metadata/presentation/cubit/metadata_plugin_state.dart';
import 'package:music_are/features/plugin/metadata/presentation/pages/metadata_plugin_update_page.dart';
import 'package:music_are/features/plugin/shared/data/models/plugin_manifest.dart';
import 'package:music_are/features/plugin/shared/data/models/plugin_type.dart';

class MockMetadataPluginCubit extends Mock implements MetadataPluginCubit {}

class MockPluginDiscoveryService extends Mock
    implements PluginDiscoveryService {}

void main() {
  late MockMetadataPluginCubit mockPluginCubit;
  late MockPluginDiscoveryService mockDiscoveryService;

  setUpAll(() {
    registerFallbackValue(PluginType.metadata);
  });

  setUp(() async {
    final sl = GetIt.instance;
    await sl.reset();

    mockPluginCubit = MockMetadataPluginCubit();
    mockDiscoveryService = MockPluginDiscoveryService();

    sl.registerLazySingleton<PluginDiscoveryService>(
      () => mockDiscoveryService,
    );
  });

  Widget buildTestableWidget() {
    return MaterialApp(
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      home: BlocProvider<MetadataPluginCubit>.value(
        value: mockPluginCubit,
        child: const MetadataPluginUpdatePage(),
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
    ).thenReturn(MetadataPluginIncompatibleState(obsoleteManifest));
    when(
      () =>
          mockDiscoveryService.fetchCommunityPlugins(type: any(named: 'type')),
    ).thenAnswer((_) async => []);

    await tester.pumpWidget(buildTestableWidget());
    await tester.pumpAndSettle();

    expect(find.text('Action Required'), findsOneWidget);
    expect(find.text('Obsolete Provider'), findsOneWidget);
    expect(find.text('Test Plugin'), findsOneWidget);
    expect(find.byType(PluginDiscoveryWidget), findsOneWidget);
  });
}
