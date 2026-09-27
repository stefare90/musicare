import 'package:flutter/material.dart';
import 'package:music_are/features/plugin/shared/data/models/plugin_manifest.dart';
import 'package:music_are/features/settings/presentation/widgets/plugin_detail_header.dart';
import 'package:music_are/features/settings/presentation/widgets/plugin_version_section.dart';

/// Common content of a plugin detail: the header, the version section, and the
/// extra sections a plugin type contributes (each with its own section header).
class PluginDetailBody extends StatelessWidget {
  final PluginManifest manifest;
  final List<Widget> sections;

  const PluginDetailBody({
    super.key,
    required this.manifest,
    this.sections = const [],
  });

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.only(bottom: 24.0),
      children: [
        PluginDetailHeader(manifest: manifest),
        PluginVersionSection(manifest: manifest),
        ...sections,
      ],
    );
  }
}
