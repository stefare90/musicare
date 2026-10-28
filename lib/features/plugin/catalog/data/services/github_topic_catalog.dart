import 'dart:convert';
import 'dart:typed_data';

import 'package:archive/archive.dart';
import 'package:music_are/core/services/network_service.dart';
import 'package:music_are/features/plugin/shared/data/services/plugin_catalog.dart';
import 'package:music_are/features/plugin/shared/data/exceptions/plugin_exceptions.dart';
import 'package:music_are/features/plugin/shared/data/models/plugin_manifest.dart';
import 'package:music_are/features/plugin/shared/data/models/plugin_type.dart';

/// GitHub plugins are repositories tagged with `topic:musicare-plugin` that
/// publish a `.zip` asset on their latest release.
class GitHubTopicCatalog implements PluginCatalog {
  static const String searchUrl =
      'https://api.github.com/search/repositories?q=topic:musicare-plugin';
  static const Duration cacheTtl = Duration(hours: 6);

  final NetworkService networkService;
  final DateTime Function() now;
  final Map<String, Uint8List> _cachedZips = {};
  Map<String, PluginManifest>? _cachedManifests;
  DateTime? _cachedAt;

  GitHubTopicCatalog({
    required this.networkService,
    this.now = DateTime.now,
  });

  @override
  Future<Map<String, PluginManifest>> latest(
    PluginType type, {
    bool forceRefresh = false,
  }) async {
    if (forceRefresh || _isStale()) {
      await _fetchAll();
    }
    final manifests = _cachedManifests ?? const {};
    return {
      for (final entry in manifests.entries)
        if (entry.value.pluginType == type) entry.key: entry.value,
    };
  }

  @override
  Future<Uint8List> download(PluginManifest manifest) async {
    final cached = _cachedZips[_cacheKey(manifest.id, manifest.version)];
    if (cached != null) return cached;

    final bytes = await _downloadReleaseAsset(manifest);
    _cachedZips[_cacheKey(manifest.id, manifest.version)] = bytes;
    return bytes;
  }

  Future<Uint8List> _downloadReleaseAsset(PluginManifest manifest) async {
    final repository = manifest.repository;
    final uri = repository == null ? null : Uri.tryParse(repository);
    if (uri == null ||
        uri.host != 'github.com' ||
        uri.pathSegments.length < 2) {
      throw PluginDownloadException(repository);
    }

    final owner = uri.pathSegments[0];
    final repo = uri.pathSegments[1].replaceAll(RegExp(r'\.git$'), '');
    for (final tag in ['v${manifest.version}', manifest.version]) {
      final url =
          'https://github.com/$owner/$repo/releases/download/$tag/plugin.zip';
      final response = await networkService.get(Uri.parse(url));
      if (response.statusCode == 200) return response.bodyBytes;
    }
    throw PluginDownloadException(repository);
  }

  bool _isStale() {
    final cachedAt = _cachedAt;
    return _cachedManifests == null ||
        cachedAt == null ||
        now().difference(cachedAt) >= cacheTtl;
  }

  Future<void> _fetchAll() async {
    _cachedManifests = null;
    _cachedZips.clear();
    _cachedAt = null;

    final response = await networkService.get(Uri.parse(searchUrl));
    if (response.statusCode != 200) {
      throw PluginSearchException(response.statusCode);
    }

    final data = jsonDecode(response.body) as Map<String, dynamic>;
    final items = data['items'] as List<dynamic>? ?? [];
    final manifests = <String, PluginManifest>{};

    for (final item in items) {
      try {
        final repo = item as Map<String, dynamic>;
        final manifest = await _latestManifestFor(repo['full_name'] as String);
        if (manifest != null) {
          manifests[manifest.id] = manifest;
        }
      } catch (_) {
        // A broken repository does not hide the other available plugins.
      }
    }

    _cachedManifests = manifests;
    _cachedAt = now();
  }

  Future<PluginManifest?> _latestManifestFor(String fullName) async {
    final releaseResponse = await networkService.get(
      Uri.parse('https://api.github.com/repos/$fullName/releases/latest'),
    );
    if (releaseResponse.statusCode != 200) return null;

    final release = jsonDecode(releaseResponse.body) as Map<String, dynamic>;
    final assets = release['assets'] as List<dynamic>? ?? [];
    String? zipUrl;
    for (final asset in assets) {
      final assetMap = asset as Map<String, dynamic>;
      if ((assetMap['name'] as String).endsWith('.zip')) {
        zipUrl = assetMap['browser_download_url'] as String;
        break;
      }
    }
    if (zipUrl == null) return null;

    final zipBytes = await _downloadZip(zipUrl);
    final manifest = _manifestFromZip(zipBytes);
    _cachedZips[_cacheKey(manifest.id, manifest.version)] = zipBytes;
    return manifest;
  }

  Future<Uint8List> _downloadZip(String url) async {
    final response = await networkService.get(Uri.parse(url));
    if (response.statusCode != 200) {
      throw PluginDownloadException(url);
    }
    return response.bodyBytes;
  }

  PluginManifest _manifestFromZip(Uint8List zipBytes) {
    final archive = ZipDecoder().decodeBytes(zipBytes);
    for (final file in archive) {
      if (file.name == 'plugin.json') {
        return PluginManifest.fromJson(
          jsonDecode(utf8.decode(file.content as List<int>))
              as Map<String, dynamic>,
        );
      }
    }
    throw InvalidPluginArchiveException();
  }

  String _cacheKey(String id, String version) => '${id}_$version';
}
