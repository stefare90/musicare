import 'package:flutter/material.dart';
import 'package:music_are/core/config/app_assets.dart';
import 'package:music_are/core/config/app_info.dart';
import 'package:music_are/core/l10n/l10n_extension.dart';
import 'package:music_are/core/theme/theme_extension.dart';

class AppVersionHeader extends StatelessWidget {
  const AppVersionHeader({super.key});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16.0, 16.0, 16.0, 8.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(12.0),
            child: Image.asset(
              AppAssets.appIcon,
              width: 40.0,
              height: 40.0,
              semanticLabel: context.l10n.appTitle,
            ),
          ),
          const SizedBox(width: 16.0),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  context.l10n.appTitle,
                  style: context.textTheme.titleLarge,
                ),
                const SizedBox(height: 2.0),
                Text(
                  context.l10n.byAuthor(AppInfo.founder),
                  style: context.textTheme.bodySmall?.copyWith(
                    color: context.colorScheme.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
