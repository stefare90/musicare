import 'dart:convert';
import 'dart:typed_data';

import 'package:archive/archive.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:mocktail/mocktail.dart';
import 'package:music_are/core/services/network_service.dart';
import 'package:music_are/features/plugin/data/services/plugin_discovery_service.dart';

class MockNetworkService extends Mock implements NetworkService {}

Uint8List createTestZipBytes() {
  final archive = Archive();
  final jsonContent = '''
  {
    "id": "org.gyawun.musicbrainz",
    "packageId": "gyawun_metadata_plugin",
    "type": "metadata",
    "name": "MusicBrainz & ListenBrainz",
    "version": "1.0.0",
    "pluginSdkVersion": "1.0.0",
    "author": "MusicAre Team",
    "description": "Test description"
  }
  ''';
  final jsonBytes = utf8.encode(jsonContent);
  archive.addFile(ArchiveFile('plugin.json', jsonBytes.length, jsonBytes));
  archive.addFile(ArchiveFile('plugin.evc', 4, [1, 2, 3, 4]));
  final encoded = ZipEncoder().encode(archive);
  return Uint8List.fromList(encoded!);
}

void main() {
  group('PluginDiscoveryService Unit Tests', () {
    late MockNetworkService mockNetworkService;
    late PluginDiscoveryService service;

    const githubSearchUriString =
        'https://api.github.com/search/repositories?q=topic:musicare-plugin';
    const releaseUriString =
        'https://api.github.com/repos/stefare90/gyawun_metadata_plugin/releases/latest';
    const zipDownloadUriString =
        'https://github.com/stefare90/gyawun_metadata_plugin/releases/download/v1.0.0/musicbrainz.zip';

    setUp(() {
      mockNetworkService = MockNetworkService();
      service = PluginDiscoveryService(networkService: mockNetworkService);
    });

    test(
      'fetchCommunityPlugins searches GitHub, downloads zip, parses manifest, and caches zip bytes',
      () async {
        final searchJsonResponse = jsonEncode({
          'items': [
            {'full_name': 'stefare90/gyawun_metadata_plugin'},
          ],
        });

        final releaseJsonResponse = jsonEncode({
          'tag_name': 'v1.0.0',
          'assets': [
            {
              'name': 'musicbrainz.zip',
              'browser_download_url': zipDownloadUriString,
            },
          ],
        });

        final zipBytes = createTestZipBytes();

        when(
          () => mockNetworkService.get(Uri.parse(githubSearchUriString)),
        ).thenAnswer((_) async => http.Response(searchJsonResponse, 200));

        when(
          () => mockNetworkService.get(Uri.parse(releaseUriString)),
        ).thenAnswer((_) async => http.Response(releaseJsonResponse, 200));

        when(
          () => mockNetworkService.get(Uri.parse(zipDownloadUriString)),
        ).thenAnswer((_) async => http.Response.bytes(zipBytes, 200));

        final manifests = await service.fetchCommunityPlugins();

        expect(manifests.length, equals(1));
        final manifest = manifests.first;
        expect(manifest.id, equals('org.gyawun.musicbrainz'));
        expect(manifest.name, equals('MusicBrainz & ListenBrainz'));

        // Verify cached zip bytes using PluginManifest instance
        final cachedBytes = service.getZipBytesForPlugin(manifest);
        expect(cachedBytes, isNotNull);
        expect(cachedBytes, equals(zipBytes));
      },
    );

    test(
      'fetchCommunityPlugins throws Exception when GitHub search fails with non-200',
      () async {
        when(
          () => mockNetworkService.get(Uri.parse(githubSearchUriString)),
        ).thenAnswer((_) async => http.Response('Rate limit exceeded', 403));

        expect(
          () async => await service.fetchCommunityPlugins(),
          throwsA(isA<Exception>()),
        );
      },
    );

    test(
      'fetchCommunityPlugins gracefully skips repo if no release zip is found',
      () async {
        final searchJsonResponse = jsonEncode({
          'items': [
            {'full_name': 'stefare90/empty_plugin'},
          ],
        });

        when(
          () => mockNetworkService.get(Uri.parse(githubSearchUriString)),
        ).thenAnswer((_) async => http.Response(searchJsonResponse, 200));

        when(
          () => mockNetworkService.get(
            Uri.parse(
              'https://api.github.com/repos/stefare90/empty_plugin/releases/latest',
            ),
          ),
        ).thenAnswer((_) async => http.Response('Not Found', 404));

        final manifests = await service.fetchCommunityPlugins();

        expect(manifests, isEmpty);
      },
    );
  });
}
