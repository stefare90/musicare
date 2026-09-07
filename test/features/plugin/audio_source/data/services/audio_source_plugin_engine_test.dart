import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:archive/archive.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:gyawun_metadata_sdk/metadata/models/album.dart';
import 'package:gyawun_metadata_sdk/metadata/models/artist.dart';
import 'package:gyawun_metadata_sdk/metadata/models/track.dart';
import 'package:mocktail/mocktail.dart';
import 'package:music_are/features/plugin/audio_source/data/services/audio_source_plugin_engine.dart';
import 'package:music_are/features/plugin/shared/data/exceptions/plugin_exceptions.dart';
import 'package:musicare_dart_host_sdk/musicare_dart_host_sdk.dart';
import 'package:path_provider_platform_interface/path_provider_platform_interface.dart';
import 'package:plugin_platform_interface/plugin_platform_interface.dart';

class MockAudioSourceClient extends Mock implements AudioSourceClient {}

class FakePathProviderPlatform extends Fake
    with MockPlatformInterfaceMixin
    implements PathProviderPlatform {
  final Directory tempDir;
  FakePathProviderPlatform(this.tempDir);

  @override
  Future<String?> getApplicationSupportPath() async => tempDir.path;
}

Uint8List createTestAudioSourceZip({
  String id = 'org.musicare.audiosource.youtube',
  String type = 'audioSource',
  bool includeJson = true,
}) {
  final archive = Archive();
  if (includeJson) {
    final jsonContent = jsonEncode({
      'id': id,
      'packageId': 'musicare_audiosource_youtube_plugin',
      'type': type,
      'name': 'YouTube Audio Source',
      'version': '1.0.0',
      'pluginSdkVersion': '1.0.0',
      'author': 'MusicAre Team',
      'description': 'Test source',
    });
    final jsonBytes = utf8.encode(jsonContent);
    archive.addFile(ArchiveFile('plugin.json', jsonBytes.length, jsonBytes));
    final pyBytes = utf8.encode('def get_plugin(): pass');
    archive.addFile(ArchiveFile('main.py', pyBytes.length, pyBytes));
  }
  final zipData = ZipEncoder().encode(archive);
  return Uint8List.fromList(zipData!);
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('AudioSourcePluginEngine Unit Tests', () {
    late MockAudioSourceClient mockClient;
    late AudioSourcePluginEngine engine;
    late Directory tempDir;
    late bool isClientStarted;

    setUp(() {
      tempDir = Directory.systemTemp.createTempSync('audio_source_test_');
      PathProviderPlatform.instance = FakePathProviderPlatform(tempDir);

      isClientStarted = false;
      mockClient = MockAudioSourceClient();

      // Stato dinamico: isStarted si aggiorna quando start() e stop() vengono chiamati
      when(() => mockClient.isStarted).thenAnswer((_) => isClientStarted);
      when(() => mockClient.port).thenReturn(8765);
      when(() => mockClient.start()).thenAnswer((_) async {
        isClientStarted = true;
      });
      when(() => mockClient.stop()).thenAnswer((_) {
        isClientStarted = false;
      });
      when(
        () => mockClient.loadPlugin(any()),
      ).thenAnswer((_) async => {'loaded': 'YouTube Audio Source'});

      engine = AudioSourcePluginEngine(client: mockClient);
    });

    tearDown(() {
      if (tempDir.existsSync()) {
        tempDir.deleteSync(recursive: true);
      }
    });

    test(
      'isPluginInstalledOnDisk returns false when files do not exist',
      () async {
        final exists = await engine.isPluginInstalledOnDisk(
          'non_existent_plugin',
        );
        expect(exists, isFalse);
      },
    );

    test(
      'loadFromDisk throws PluginFileNotFoundException when directory is missing',
      () async {
        expect(
          () async => await engine.loadFromDisk('missing_plugin'),
          throwsA(isA<PluginFileNotFoundException>()),
        );
      },
    );

    test(
      'loadFromZipBytes unpacks zip, starts client, and loads plugin successfully',
      () async {
        final zipBytes = createTestAudioSourceZip();

        await engine.loadFromZipBytes(zipBytes);

        expect(engine.isRunning, isTrue);
        expect(
          engine.activePluginId,
          equals('org.musicare.audiosource.youtube'),
        );
        expect(engine.activePort, equals(8765));
        expect(engine.activeManifest?.name, equals('YouTube Audio Source'));

        verify(() => mockClient.start()).called(1);
        verify(() => mockClient.loadPlugin(any())).called(1);
      },
    );

    test(
      'loadFromZipBytes throws InvalidPluginArchiveException when plugin.json is absent',
      () async {
        final corruptZip = createTestAudioSourceZip(includeJson: false);

        expect(
          () async => await engine.loadFromZipBytes(corruptZip),
          throwsA(isA<InvalidPluginArchiveException>()),
        );
      },
    );

    test(
      'loadFromZipBytes throws InvalidPluginTypeException if manifest type is not audioSource',
      () async {
        final metadataZip = createTestAudioSourceZip(type: 'metadata');

        expect(
          () async => await engine.loadFromZipBytes(metadataZip),
          throwsA(isA<InvalidPluginTypeException>()),
        );
      },
    );

    test(
      'resolveStream throws PluginNotLoadedException when engine is not running',
      () async {
        final track = Track(
          id: 't1',
          name: 'Test Song',
          externalUri: '',
          artists: [Artist(id: 'a1', name: 'Artist', externalUri: '')],
          album: Album(
            id: 'al1',
            name: 'Album',
            artists: [],
            releaseDate: '',
            externalUri: '',
            totalTracks: 1,
            albumType: AlbumType.single,
          ),
          durationMs: 120000,
        );

        expect(
          () async => await engine.resolveStream(track),
          throwsA(isA<PluginNotLoadedException>()),
        );
      },
    );

    test('resolveStream delegates to client when running', () async {
      final zipBytes = createTestAudioSourceZip();
      await engine.loadFromZipBytes(zipBytes);

      const streamResponse = AudioStreamResponse(
        url: 'https://cdn.example.com/audio.m4a',
        quality: AudioQuality.high,
        bitrate: 160000,
      );

      when(
        () => mockClient.getStream(
          title: 'Test Song',
          artists: ['Artist'],
          durationMs: 120000,
          quality: AudioQuality.high,
        ),
      ).thenAnswer((_) async => [streamResponse]);

      final track = Track(
        id: 't1',
        name: 'Test Song',
        externalUri: '',
        artists: [Artist(id: 'a1', name: 'Artist', externalUri: '')],
        album: Album(
          id: 'al1',
          name: 'Album',
          artists: [],
          releaseDate: '',
          externalUri: '',
          totalTracks: 1,
          albumType: AlbumType.single,
        ),
        durationMs: 120000,
      );

      final result = await engine.resolveStream(track);

      expect(result.length, equals(1));
      expect(result.first.url, equals('https://cdn.example.com/audio.m4a'));
    });

    test('terminate stops client and clears active state', () async {
      final zipBytes = createTestAudioSourceZip();
      await engine.loadFromZipBytes(zipBytes);

      expect(engine.isRunning, isTrue);

      await engine.terminate();

      expect(engine.isRunning, isFalse);
      expect(engine.activeManifest, isNull);
      verify(() => mockClient.stop()).called(1);
    });
  });
}
