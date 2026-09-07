import 'dart:convert';
import 'dart:typed_data';
import 'package:archive/archive.dart';
import 'package:music_are/core/services/network_service.dart';
import 'package:music_are/features/plugin/shared/data/exceptions/plugin_exceptions.dart';
import 'package:music_are/features/plugin/shared/data/models/plugin_manifest.dart';
import 'package:music_are/features/plugin/shared/data/models/plugin_type.dart';

class PluginDiscoveryService {
  static const String githubSearchUrl =
      'https://api.github.com/search/repositories?q=topic:musicare-plugin';

  final NetworkService _networkService;
  final Map<String, Uint8List> _cachedPluginZips = {};
  List<PluginManifest>? _cachedManifests;

  PluginDiscoveryService({required this._networkService});

  String _buildCacheKey(String id, String version) => '${id}_$version';

  Future<List<PluginManifest>> fetchCommunityPlugins({
    PluginType? type,
    bool forceRefresh = false,
  }) async {
    if (_cachedManifests != null && !forceRefresh) {
      if (type != null) {
        return _cachedManifests!.where((m) => m.pluginType == type).toList();
      }
      return _cachedManifests!;
    }
    _cachedManifests = null;
    _cachedPluginZips.clear();
    final response = await _networkService.get(Uri.parse(githubSearchUrl));
    if (response.statusCode != 200) {
      throw PluginSearchException(response.statusCode);
    }

    final data = jsonDecode(response.body) as Map<String, dynamic>;
    final items = data['items'] as List<dynamic>? ?? [];
    final List<PluginManifest> manifests = [];

    for (final item in items) {
      final repoMap = item as Map<String, dynamic>;
      final String fullName = repoMap['full_name'] as String;
      final releaseUrl =
          'https://api.github.com/repos/$fullName/releases/latest';

      try {
        final releaseResponse = await _networkService.get(
          Uri.parse(releaseUrl),
        );
        if (releaseResponse.statusCode == 200) {
          final releaseData =
              jsonDecode(releaseResponse.body) as Map<String, dynamic>;
          final assets = releaseData['assets'] as List<dynamic>? ?? [];

          String? zipDownloadUrl;
          for (final asset in assets) {
            final assetMap = asset as Map<String, dynamic>;
            final String name = assetMap['name'] as String;
            if (name.endsWith('.zip')) {
              zipDownloadUrl = assetMap['browser_download_url'] as String;
              break;
            }
          }

          if (zipDownloadUrl != null) {
            final zipBytes = await downloadPluginZip(zipDownloadUrl);
            final archive = ZipDecoder().decodeBytes(zipBytes);
            String? jsonContent;

            for (final file in archive) {
              if (file.name == 'plugin.json') {
                jsonContent = utf8.decode(file.content as List<int>);
                break;
              }
            }

            if (jsonContent != null) {
              final manifestMap =
                  jsonDecode(jsonContent) as Map<String, dynamic>;
              final manifest = PluginManifest.fromJson(manifestMap);

              _cachedPluginZips[_buildCacheKey(manifest.id, manifest.version)] =
                  zipBytes;
              manifests.add(manifest);
            }
          }
        }
      } catch (_) {
        // Skip individual repository failures
      }
    }

    _cachedManifests = manifests;

    if (type != null) {
      return manifests.where((m) => m.pluginType == type).toList();
    }
    return manifests;
  }

  Future<Uint8List> downloadPluginZip(String downloadUrl) async {
    final response = await _networkService.get(Uri.parse(downloadUrl));
    if (response.statusCode != 200) {
      throw PluginDownloadException(downloadUrl);
    }
    return response.bodyBytes;
  }

  Uint8List getZipBytesForPlugin(PluginManifest manifest) {
    final bytes =
        _cachedPluginZips[_buildCacheKey(manifest.id, manifest.version)];
    if (bytes == null) {
      throw InvalidPluginArchiveException();
    }
    return bytes;
  }
}
