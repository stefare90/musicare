import 'package:flutter/material.dart';
import 'package:music_are/core/l10n/l10n_extension.dart';
import 'package:music_are/core/theme/theme_extension.dart';
import 'package:music_are/features/settings/presentation/widgets/settings_section_header.dart';
import 'package:musicare_audio_host_sdk/musicare_audio_host_sdk.dart'
    as audio_sdk;
import 'package:musicare_metadata_host_sdk/musicare_metadata_host_sdk.dart'
    as metadata_sdk;
import 'package:package_info_plus/package_info_plus.dart';

class AboutPage extends StatefulWidget {
  const AboutPage({super.key});

  @override
  State<AboutPage> createState() => _AboutPageState();
}

class _AboutPageState extends State<AboutPage> {
  late final Future<PackageInfo> _packageInfo = PackageInfo.fromPlatform();

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;

    return Scaffold(
      appBar: AppBar(title: Text(l10n.settingsAboutTile)),
      body: ListView(
        padding: const EdgeInsets.only(bottom: 24.0),
        children: [
          FutureBuilder<PackageInfo>(
            future: _packageInfo,
            builder: (context, snapshot) {
              final info = snapshot.data;
              final version = info == null
                  ? '—'
                  : 'v${info.version} (${info.buildNumber})';
              return _InfoRow(
                label: l10n.settingsAboutAppVersion,
                value: version,
              );
            },
          ),
          SettingsSectionHeader(label: l10n.settingsAboutHostSdksSection),
          _InfoRow(
            label: l10n.settingsAboutMetadataSdk,
            value: metadata_sdk.packageVersion,
          ),
          _InfoRow(
            label: l10n.settingsAboutAudioSdk,
            value: audio_sdk.packageVersion,
          ),
        ],
      ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  final String label;
  final String value;

  const _InfoRow({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return ListTile(
      dense: true,
      title: Text(label),
      trailing: Text(
        value,
        style: context.textTheme.bodyMedium?.copyWith(
          color: context.colorScheme.onSurfaceVariant,
        ),
      ),
    );
  }
}
