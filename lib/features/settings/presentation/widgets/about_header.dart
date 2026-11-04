import 'package:flutter/material.dart';
import 'package:music_are/core/config/app_assets.dart';
import 'package:music_are/core/l10n/l10n_extension.dart';
import 'package:music_are/core/theme/theme_extension.dart';
import 'package:package_info_plus/package_info_plus.dart';

class AboutHeader extends StatelessWidget {
  final Future<PackageInfo> packageInfo;

  const AboutHeader({super.key, required this.packageInfo});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        const SizedBox(height: 24.0),
        ClipRRect(
          borderRadius: BorderRadius.circular(24.0),
          child: Image.asset(
            AppAssets.appIcon,
            width: 96.0,
            height: 96.0,
            semanticLabel: context.l10n.appTitle,
          ),
        ),
        const SizedBox(height: 12.0),
        Text(context.l10n.appTitle, style: context.textTheme.titleLarge),
        const SizedBox(height: 2.0),
        FutureBuilder<PackageInfo>(
          future: packageInfo,
          builder: (context, snapshot) {
            final info = snapshot.data;
            final version = info == null
                ? '—'
                : 'v${info.version} (${info.buildNumber})';
            return Text(
              version,
              style: context.textTheme.bodyMedium?.copyWith(
                color: context.colorScheme.onSurfaceVariant,
              ),
            );
          },
        ),
        const SizedBox(height: 8.0),
      ],
    );
  }
}
