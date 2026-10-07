import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:musicare_metadata_host_sdk/musicare_metadata_host_sdk.dart';
import 'package:music_are/core/l10n/l10n_extension.dart';
import 'package:music_are/core/theme/theme_extension.dart';
import 'package:music_are/features/plugin/metadata/presentation/cubit/user_cubit.dart';

class FavoriteButton extends StatelessWidget {
  final Track track;

  const FavoriteButton({super.key, required this.track});

  @override
  Widget build(BuildContext context) {
    final isSaved = context.select<UserCubit, bool>(
      (c) => c.isTrackSaved(track.id),
    );
    return IconButton(
      icon: Icon(
        isSaved ? Icons.favorite_rounded : Icons.favorite_border_rounded,
      ),
      color: isSaved ? context.colorScheme.primary : null,
      tooltip: context.l10n.tooltipFavorite,
      onPressed: () => context.read<UserCubit>().toggleTrack(track),
    );
  }
}
