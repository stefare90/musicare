import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:music_are/features/plugin/shared/data/models/plugin_type.dart';
import 'package:music_are/features/plugin/shared/presentation/utils/plugin_type_icon.dart';

void main() {
  test('PluginTypeIcon matches the onboarding step icons', () {
    expect(PluginType.metadata.icon, Icons.library_music_rounded);
    expect(PluginType.audioSource.icon, Icons.graphic_eq_rounded);
  });
}
