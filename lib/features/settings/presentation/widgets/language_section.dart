import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:music_are/core/l10n/app_localizations.dart';
import 'package:music_are/core/l10n/l10n_extension.dart';
import 'package:music_are/core/theme/presentation/cubit/theme_cubit.dart';

class LanguageSection extends StatelessWidget {
  const LanguageSection({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final locale = context.select<ThemeCubit, Locale?>(
      (cubit) => cubit.state.locale,
    );
    final locales = AppLocalizations.supportedLocales;
    final current = locale?.languageCode ?? locales.first.languageCode;

    return ListTile(
      title: Text(l10n.settingsLanguageLabel),
      trailing: DropdownButton<String>(
        value: current,
        underline: const SizedBox.shrink(),
        onChanged: (code) {
          if (code != null) {
            context.read<ThemeCubit>().setLocale(Locale(code));
          }
        },
        items: [
          for (final locale in locales)
            DropdownMenuItem(
              value: locale.languageCode,
              child: Text(_languageLabel(context, locale)),
            ),
        ],
      ),
    );
  }
}

String _languageLabel(BuildContext context, Locale locale) {
  return switch (locale.languageCode) {
    'en' => context.l10n.settingsLanguageEnglish,
    _ => locale.languageCode.toUpperCase(),
  };
}
