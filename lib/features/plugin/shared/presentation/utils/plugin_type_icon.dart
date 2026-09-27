import 'package:flutter/material.dart';
import 'package:music_are/features/plugin/shared/data/models/plugin_type.dart';

extension PluginTypeIcon on PluginType {
  IconData get icon => switch (this) {
    PluginType.metadata => Icons.library_music_rounded,
    PluginType.audioSource => Icons.graphic_eq_rounded,
  };
}
