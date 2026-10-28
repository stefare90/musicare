import 'package:music_are/core/services/preferences_service.dart';
import 'package:music_are/features/plugin/shared/data/exceptions/plugin_exceptions.dart';
import 'package:music_are/features/plugin/shared/data/models/plugin_manifest.dart';
import 'package:music_are/features/plugin/shared/data/models/plugin_type.dart';
import 'package:music_are/features/plugin/shared/data/models/plugin_version.dart';
import 'package:music_are/features/plugin/management/data/models/plugin_slot_data.dart';
import 'package:music_are/features/plugin/shared/data/services/plugin_storage.dart';
import 'package:music_are/features/plugin/shared/data/services/plugin_catalog.dart';
import 'package:music_are/features/plugin/shared/data/capabilities/plugin_lifecycle.dart';
import 'package:music_are/features/plugin/shared/data/services/plugin_registry.dart';

class PluginManager {
  PluginManager({
    required this.registry,
    required this.catalog,
    required this.storage,
    required this.preferences,
  });

  final PluginRegistry registry;
  final PluginCatalog catalog;
  final PluginStorage storage;
  final PreferencesService preferences;
  PluginLifecycleState pluginState(PluginType type) =>
      registry.entryOf(type).lifecycle.state;

  Future<void> initialize() async {
    for (final entry in registry.entries) {
      final type = entry.type;
      try {
        final id = preferences.activePluginId(type);
        if (id == null || id.isEmpty) continue;
        final manifest = await storage.installed(type, id);
        if (manifest == null) continue;
        final dir = await storage.codeDir(type, id);
        final error = await entry.lifecycle.load(id, dir);
        if (error == null) await entry.auth?.refresh();
      } catch (_) {}
    }
  }

  Future<PluginSlotData> snapshot(
    PluginType type, {
    bool fetchCatalog = true,
  }) async {
    final plugin = registry.entryOf(type).lifecycle;
    final id = preferences.activePluginId(type);
    final installed = id == null ? null : await storage.installed(type, id);

    PluginManifest? remote;
    var updateAvailable = false;
    if (fetchCatalog) {
      final manifests = await catalog.latest(type);
      remote = installed == null ? null : manifests[installed.id];
      if (installed != null && remote != null && plugin.isCompatible(remote)) {
        updateAvailable =
            (comparePluginVersions(remote.version, installed.version) ?? 0) > 0;
      }
    }

    return PluginSlotData(
      installed: installed,
      remote: remote,
      updateAvailable: updateAvailable,
      incompatible: installed != null && !plugin.isCompatible(installed),
    );
  }

  Future<List<PluginManifest>> alternatives(PluginType type) async {
    final plugin = registry.entryOf(type).lifecycle;
    final activeId = preferences.activePluginId(type);
    final manifests = await catalog.latest(type);
    return manifests.values
        .where(
          (manifest) =>
              manifest.id != activeId && plugin.isCompatible(manifest),
        )
        .toList()
      ..sort((a, b) => a.name.toLowerCase().compareTo(b.name.toLowerCase()));
  }

  Future<PluginManifest> apply(PluginType type, PluginManifest target) async {
    final entry = registry.entryOf(type);
    final plugin = entry.lifecycle;
    if (!plugin.isCompatible(target)) {
      throw IncompatibleSdkVersionException(
        manifest: target,
        hostVersion: plugin.hostSdkVersion,
      );
    }

    final previousId = preferences.activePluginId(type);
    final zipBytes = await catalog.download(target);
    final manifest = await storage.install(
      type,
      zipBytes,
      validate: plugin.validate,
    );
    final isSwitch = previousId != null && previousId != manifest.id;

    if (isSwitch) {
      try {
        await entry.auth?.logout();
      } catch (_) {}
    }

    final dir = await storage.codeDir(type, manifest.id);
    final error = await plugin.load(manifest.id, dir);
    if (error != null) {
      await storage.rollback(type, manifest.id);
      throw PluginActivationException(error);
    }

    await storage.commit(type, manifest.id);
    await preferences.setActivePluginId(type, manifest.id);
    await entry.auth?.refresh();

    if (isSwitch) {
      await storage.removeCodeDir(type, previousId);
      await preferences.removePluginScopedKeys(previousId);
    }

    return manifest;
  }
}
