import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:music_are/core/l10n/l10n_extension.dart';
import 'package:music_are/core/theme/app_accent.dart';
import 'package:music_are/core/theme/presentation/cubit/theme_cubit.dart';

class AccentColorSection extends StatelessWidget {
  const AccentColorSection({super.key});

  @override
  Widget build(BuildContext context) {
    final selected = context.select<ThemeCubit, AppAccent>(
      (cubit) => cubit.state.accent,
    );

    return ListTile(
      title: Text(context.l10n.settingsAccentColorLabel),
      trailing: DropdownButton<AppAccent>(
        value: selected,
        underline: const SizedBox.shrink(),
        onChanged: (accent) {
          if (accent != null) {
            context.read<ThemeCubit>().setAccent(accent);
          }
        },
        items: [
          for (final accent in AppAccent.values)
            DropdownMenuItem(
              value: accent,
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 14.0,
                    height: 14.0,
                    decoration: BoxDecoration(
                      color: accent.color,
                      shape: BoxShape.circle,
                    ),
                  ),
                  const SizedBox(width: 8.0),
                  Text(_accentLabel(context, accent)),
                ],
              ),
            ),
        ],
      ),
    );
  }
}

String _accentLabel(BuildContext context, AppAccent accent) {
  final l10n = context.l10n;
  return switch (accent) {
    AppAccent.violet => l10n.settingsAccentViolet,
    AppAccent.blue => l10n.settingsAccentBlue,
    AppAccent.cyan => l10n.settingsAccentCyan,
    AppAccent.teal => l10n.settingsAccentTeal,
    AppAccent.green => l10n.settingsAccentGreen,
    AppAccent.amber => l10n.settingsAccentAmber,
    AppAccent.orange => l10n.settingsAccentOrange,
    AppAccent.pink => l10n.settingsAccentPink,
  };
}
