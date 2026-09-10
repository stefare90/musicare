import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:music_are/core/theme/theme_extension.dart';
import 'package:music_are/features/player/data/models/playback_repeat_mode.dart';
import 'package:music_are/features/player/presentation/cubit/player_cubit.dart';
import 'package:music_are/features/player/presentation/cubit/player_state.dart';

class PlayerPlaybackControls extends StatelessWidget {
  final PlayerState state;

  const PlayerPlaybackControls({super.key, required this.state});

  @override
  Widget build(BuildContext context) {
    final player = context.read<PlayerCubit>();

    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        IconButton(
          icon: const Icon(Icons.shuffle_rounded),
          color: state.queue.isShuffled
              ? context.colorScheme.primary
              : context.colorScheme.onSurfaceVariant,
          onPressed: () => player.toggleShuffle(),
        ),
        IconButton(
          icon: const Icon(Icons.skip_previous_rounded, size: 38),
          onPressed: state.queue.hasPrevious ? () => player.previous() : null,
        ),
        Container(
          width: 64,
          height: 64,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: context.colorScheme.primary,
          ),
          child: state.isLoading
              ? Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: CircularProgressIndicator(
                    strokeWidth: 3,
                    color: context.colorScheme.onPrimary,
                  ),
                )
              : IconButton(
                  icon: Icon(
                    state.isPlaying
                        ? Icons.pause_rounded
                        : Icons.play_arrow_rounded,
                    size: 38,
                    color: context.colorScheme.onPrimary,
                  ),
                  onPressed: () => player.togglePlayPause(),
                ),
        ),
        IconButton(
          icon: const Icon(Icons.skip_next_rounded, size: 38),
          onPressed: state.queue.hasNext ? () => player.next() : null,
        ),
        IconButton(
          icon: Icon(
            state.queue.repeatMode == PlaybackRepeatMode.one
                ? Icons.repeat_one_rounded
                : Icons.repeat_rounded,
          ),
          color: state.queue.repeatMode != PlaybackRepeatMode.off
              ? context.colorScheme.primary
              : context.colorScheme.onSurfaceVariant,
          onPressed: () => player.cycleRepeatMode(),
        ),
      ],
    );
  }
}
