import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:music_are/core/theme/theme_extension.dart';
import 'package:music_are/features/player/presentation/cubit/player_cubit.dart';
import 'package:music_are/features/player/presentation/cubit/player_state.dart';

class PlaybackProgressBar extends StatelessWidget {
  final double height;
  final Color? color;
  final Color? backgroundColor;

  const PlaybackProgressBar({
    super.key,
    this.height = 2.0,
    this.color,
    this.backgroundColor = Colors.transparent,
  });

  @override
  Widget build(BuildContext context) {
    return BlocSelector<PlayerCubit, PlayerState, double>(
      selector: (state) {
        if (state.duration.inMilliseconds <= 0) return 0.0;
        return (state.position.inMilliseconds / state.duration.inMilliseconds)
            .clamp(0.0, 1.0);
      },
      builder: (context, progress) {
        return RepaintBoundary(
          child: SizedBox(
            width: double.infinity,
            height: height,
            child: LinearProgressIndicator(
              value: progress,
              backgroundColor: backgroundColor,
              valueColor: AlwaysStoppedAnimation<Color>(
                color ?? context.colorScheme.primary,
              ),
            ),
          ),
        );
      },
    );
  }
}
