import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:music_are/core/l10n/l10n_extension.dart';
import 'package:music_are/core/theme/presentation/cubit/theme_cubit.dart';

class AmoledBlackSwitch extends StatelessWidget {
  const AmoledBlackSwitch({super.key});

  @override
  Widget build(BuildContext context) {
    final amoledBlack = context.select<ThemeCubit, bool>(
      (cubit) => cubit.state.amoledBlack,
    );

    return SwitchListTile(
      title: Text(context.l10n.settingsAmoledLabel),
      subtitle: Text(context.l10n.settingsAmoledSubtitle),
      value: amoledBlack,
      onChanged: context.read<ThemeCubit>().setAmoledBlack,
    );
  }
}
