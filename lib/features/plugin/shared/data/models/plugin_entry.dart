import 'package:music_are/features/plugin/shared/data/capabilities/plugin_auth.dart';
import 'package:music_are/features/plugin/shared/data/capabilities/plugin_lifecycle.dart';
import 'package:music_are/features/plugin/shared/data/models/plugin_type.dart';

class PluginEntry {
  final PluginLifecycle lifecycle;
  final PluginAuth? auth;

  PluginEntry({required this.lifecycle, this.auth});

  PluginType get type => lifecycle.type;
}
