import 'package:music_are/features/plugin/shared/data/models/plugin_manifest.dart';

enum PluginLifecycleStatus {
  notConfigured,
  loading,
  loaded,
  incompatible,
  error,
}

class PluginLifecycleState {
  final PluginLifecycleStatus status;
  final PluginManifest? manifest;
  final Object? error;
  final int? port;

  const PluginLifecycleState.notConfigured()
    : status = PluginLifecycleStatus.notConfigured,
      manifest = null,
      error = null,
      port = null;

  const PluginLifecycleState.loading()
    : status = PluginLifecycleStatus.loading,
      manifest = null,
      error = null,
      port = null;

  const PluginLifecycleState.loaded(PluginManifest this.manifest, {this.port})
    : status = PluginLifecycleStatus.loaded,
      error = null;

  const PluginLifecycleState.incompatible(PluginManifest this.manifest)
    : status = PluginLifecycleStatus.incompatible,
      error = null,
      port = null;

  const PluginLifecycleState.failure(Object this.error)
    : status = PluginLifecycleStatus.error,
      manifest = null,
      port = null;

  bool get isLoaded => status == PluginLifecycleStatus.loaded;

  @override
  bool operator ==(Object other) {
    return other is PluginLifecycleState &&
        other.status == status &&
        other.manifest?.id == manifest?.id &&
        other.manifest?.version == manifest?.version &&
        other.error == error &&
        other.port == port;
  }

  @override
  int get hashCode =>
      Object.hash(status, manifest?.id, manifest?.version, error, port);
}
