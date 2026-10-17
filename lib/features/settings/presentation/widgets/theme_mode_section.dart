import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:music_are/core/l10n/l10n_extension.dart';
import 'package:music_are/core/theme/presentation/cubit/theme_cubit.dart';

class ThemeModeSection extends StatelessWidget {
  const ThemeModeSection({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final themeMode = context.select<ThemeCubit, ThemeMode>(
      (cubit) => cubit.state.themeMode,
    );

    return ListTile(
      title: Text(l10n.settingsThemeLabel),
      trailing: DropdownButton<ThemeMode>(
        value: themeMode,
        underline: const SizedBox.shrink(),
        onChanged: (mode) {
          if (mode != null) {
            context.read<ThemeCubit>().setThemeMode(mode);
          }
        },
        items: [
          DropdownMenuItem(
            value: ThemeMode.system,
            child: Text(l10n.settingsThemeSystem),
          ),
          DropdownMenuItem(
            value: ThemeMode.light,
            child: Text(l10n.settingsThemeLight),
          ),
          DropdownMenuItem(
            value: ThemeMode.dark,
            child: Text(l10n.settingsThemeDark),
          ),
        ],
      ),
    );
  }
}
