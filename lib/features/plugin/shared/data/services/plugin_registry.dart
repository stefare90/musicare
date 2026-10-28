import 'package:music_are/features/plugin/shared/data/models/plugin_entry.dart';
import 'package:music_are/features/plugin/shared/data/models/plugin_type.dart';

class PluginRegistry {
  PluginRegistry(List<PluginEntry> entries)
    : _entries = {for (final entry in entries) entry.type: entry};

  final Map<PluginType, PluginEntry> _entries;

  PluginEntry entryOf(PluginType type) => _entries[type]!;

  Iterable<PluginEntry> get entries => _entries.values;
}
