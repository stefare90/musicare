import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:archive/archive.dart';
import 'package:dart_eval/dart_eval.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get_it/get_it.dart';
import 'package:gyawun_metadata_sdk/eval/eval_plugin.dart';
import 'package:gyawun_metadata_sdk/metadata/host_env.dart';
import 'package:gyawun_metadata_sdk/metadata/interfaces/inetwork_service.dart';
import 'package:gyawun_metadata_sdk/metadata/interfaces/istorage_service.dart';
import 'package:gyawun_metadata_sdk/metadata/interfaces/iui_service.dart';
import 'package:mocktail/mocktail.dart';
import 'package:music_are/features/plugin/metadata/data/services/metadata_plugin_engine.dart';
import 'package:music_are/features/plugin/shared/data/exceptions/plugin_exceptions.dart';
import 'package:path_provider_platform_interface/path_provider_platform_interface.dart';
import 'package:plugin_platform_interface/plugin_platform_interface.dart';

class MockNetworkService extends Mock implements INetworkService {}

class MockStorageService extends Mock implements IStorageService {}

class MockUiService extends Mock implements IUIService {}

class FakePathProviderPlatform extends Fake
    with MockPlatformInterfaceMixin
    implements PathProviderPlatform {
  final Directory tempDir;
  FakePathProviderPlatform(this.tempDir);

  @override
  Future<String?> getApplicationSupportPath() async {
    return tempDir.path;
  }
}

Uint8List compileTestPluginBytecode() {
  final compiler = Compiler();
  compiler.addPlugin(GyawunMetadataSdkPlugin());

  final sources = {
    'main.dart': '''
import 'package:gyawun_metadata_sdk/metadata/host_env.dart';
import 'package:gyawun_metadata_sdk/metadata/interfaces/imetadata_plugin.dart';

class TestMetadataPlugin extends IMetadataPlugin {}

IMetadataPlugin getPlugin(HostEnv hostEnv) {
  return TestMetadataPlugin();
}
''',
  };

  final program = compiler.compile({'gyawun_metadata_plugin': sources});
  return program.write();
}

Uint8List createTestPluginZip({
  required String sdkVersion,
  String pluginId = 'org.gyawun.testplugin',
  bool includeJson = true,
  bool includeEvc = true,
}) {
  final archive = Archive();

  if (includeEvc) {
    final evcBytes = compileTestPluginBytecode();
    archive.addFile(ArchiveFile('plugin.evc', evcBytes.length, evcBytes));
  }

  if (includeJson) {
    final jsonContent =
        '''
    {
      "id": "$pluginId",
      "packageId": "gyawun_metadata_plugin",
      "type": "metadata",
      "name": "Test Plugin",
      "version": "1.0.0",
      "pluginSdkVersion": "$sdkVersion",
      "author": "Test Author",
      "description": "Test Plugin Description"
    }
    ''';
    final jsonBytes = utf8.encode(jsonContent);
    archive.addFile(ArchiveFile('plugin.json', jsonBytes.length, jsonBytes));
  }

  final zipData = ZipEncoder().encode(archive);
  return Uint8List.fromList(zipData!);
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('MetadataPluginEngine Unit Tests', () {
    late MetadataPluginEngine engine;
    late Directory tempDirectory;

    setUp(() async {
      tempDirectory = Directory.systemTemp.createTempSync(
        'metadata_plugin_engine_test_',
      );
      PathProviderPlatform.instance = FakePathProviderPlatform(tempDirectory);

      final sl = GetIt.instance;
      await sl.reset();

      sl.registerLazySingleton<INetworkService>(() => MockNetworkService());
      sl.registerLazySingleton<IStorageService>(() => MockStorageService());
      sl.registerLazySingleton<IUIService>(() => MockUiService());

      engine = MetadataPluginEngine();
    });

    tearDown(() {
      if (tempDirectory.existsSync()) {
        tempDirectory.deleteSync(recursive: true);
      }
    });

    test(
      'loadFromZipBytes unzips, validates SemVer, extracts to plugins/metadata/ and initializes VM',
      () async {
        final validZipBytes = createTestPluginZip(
          sdkVersion: HostEnv.sdkVersion,
        );

        expect(engine.hasMetadata, isFalse);

        await engine.loadFromZipBytes(validZipBytes);

        expect(engine.hasMetadata, isTrue);
        expect(engine.metadataManifest, isNotNull);
        expect(engine.metadataManifest!.id, equals('org.gyawun.testplugin'));
        expect(engine.metadata, isNotNull);

        final isInstalled = await engine.isPluginInstalledOnDisk(
          'org.gyawun.testplugin',
        );
        expect(isInstalled, isTrue);
      },
    );

    test(
      'loadFromZipBytes throws IncompatibleSdkVersionException when SDK version is incompatible',
      () async {
        final incompatibleZipBytes = createTestPluginZip(sdkVersion: '1.0.0');

        expect(
          () async => await engine.loadFromZipBytes(incompatibleZipBytes),
          throwsA(isA<IncompatibleSdkVersionException>()),
        );
      },
    );

    test(
      'accessing metadata property when plugin is unloaded throws PluginNotLoadedException',
      () {
        expect(() => engine.metadata, throwsA(isA<PluginNotLoadedException>()));
      },
    );
  });
}
