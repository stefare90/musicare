import 'package:flutter/material.dart';
import 'package:music_are/core/config/app_info.dart';
import 'package:music_are/core/l10n/l10n_extension.dart';
import 'package:music_are/core/license/app_license.dart';
import 'package:music_are/core/widgets/dialogs.dart';
import 'package:music_are/features/settings/presentation/widgets/about_header.dart';
import 'package:music_are/features/settings/presentation/widgets/settings_section_header.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:url_launcher/url_launcher.dart';

class AboutPage extends StatefulWidget {
  const AboutPage({super.key});

  @override
  State<AboutPage> createState() => _AboutPageState();
}

class _AboutPageState extends State<AboutPage> {
  late final Future<PackageInfo> _packageInfo = PackageInfo.fromPlatform();

  Future<void> _openLink(String url) async {
    var opened = false;
    try {
      opened = await launchUrl(
        Uri.parse(url),
        mode: LaunchMode.externalApplication,
      );
    } on Exception {
      opened = false;
    }
    if (!opened && mounted) {
      Dialogs.showMessageSnackBar(
        context,
        message: context.l10n.linkOpenFailed,
      );
    }
  }

  Future<void> _showLicenses() async {
    final info = await _packageInfo;
    if (!mounted) return;
    showLicensePage(
      context: context,
      applicationName: AppInfo.name,
      applicationVersion: '${info.version} (${info.buildNumber})',
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;

    return Scaffold(
      appBar: AppBar(title: Text(l10n.settingsAboutTile)),
      body: ListView(
        padding: const EdgeInsets.only(bottom: 24.0),
        children: [
          AboutHeader(packageInfo: _packageInfo),
          SettingsSectionHeader(label: l10n.settingsAboutProjectSection),
          ListTile(
            leading: const Icon(Icons.person_outline_rounded),
            title: Text(l10n.settingsAboutFounder),
            subtitle: const Text(AppInfo.founder),
            trailing: const Icon(Icons.open_in_new_rounded),
            onTap: () => _openLink(AppInfo.websiteUrl),
          ),
          ListTile(
            leading: const Icon(Icons.code_rounded),
            title: Text(l10n.settingsAboutSourceCode),
            subtitle: const Text(AppInfo.repositoryLabel),
            trailing: const Icon(Icons.open_in_new_rounded),
            onTap: () => _openLink(AppInfo.repositoryUrl),
          ),
          SettingsSectionHeader(label: l10n.settingsAboutLegalSection),
          ListTile(
            leading: const Icon(Icons.description_outlined),
            title: Text(l10n.settingsAboutLicense),
            subtitle: const Text(AppLicense.spdx),
            trailing: const Icon(Icons.open_in_new_rounded),
            onTap: _showLicenses,
          ),
        ],
      ),
    );
  }
}
