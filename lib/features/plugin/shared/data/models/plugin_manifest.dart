import 'package:music_are/features/plugin/shared/data/models/plugin_type.dart';

class PluginManifest {
  final String id;
  final String packageId;
  final String type;
  final String name;
  final String version;
  final String pluginSdkVersion;
  final String author;
  final String description;
  final String? repository;

  PluginManifest({
    required this.id,
    required this.packageId,
    required this.type,
    required this.name,
    required this.version,
    required this.pluginSdkVersion,
    required this.author,
    required this.description,
    this.repository,
  });

  PluginType? get pluginType => PluginType.fromString(type);

  factory PluginManifest.fromJson(Map<String, dynamic> json) {
    return PluginManifest(
      id: json['id'] as String,
      packageId: json['packageId'] as String,
      type: json['type'] as String,
      name: json['name'] as String,
      version: json['version'] as String,
      pluginSdkVersion: json['pluginSdkVersion'] ?? json['version'] as String,
      author: json['author'] as String,
      description: json['description'] as String,
      repository: json['repository'] as String?,
    );
  }
}
