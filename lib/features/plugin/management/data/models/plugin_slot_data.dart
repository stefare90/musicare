import 'package:music_are/features/plugin/shared/data/models/plugin_manifest.dart';

class PluginSlotData {
  final PluginManifest? installed;
  final PluginManifest? remote;
  final bool updateAvailable;
  final bool incompatible;

  const PluginSlotData({
    this.installed,
    this.remote,
    this.updateAvailable = false,
    this.incompatible = false,
  });
}
