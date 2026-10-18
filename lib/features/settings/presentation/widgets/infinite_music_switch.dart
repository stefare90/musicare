import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:music_are/core/l10n/l10n_extension.dart';
import 'package:music_are/features/player/presentation/cubit/playback_settings_cubit.dart';

class InfiniteMusicSwitch extends StatelessWidget {
  const InfiniteMusicSwitch({super.key});

  @override
  Widget build(BuildContext context) {
    final infiniteMusic = context.select<PlaybackSettingsCubit, bool>(
      (cubit) => cubit.state.infiniteMusic,
    );

    return SwitchListTile(
      title: Text(context.l10n.settingsInfiniteMusicLabel),
      subtitle: Text(context.l10n.settingsInfiniteMusicSubtitle),
      value: infiniteMusic,
      onChanged: context.read<PlaybackSettingsCubit>().setInfiniteMusic,
    );
  }
}
