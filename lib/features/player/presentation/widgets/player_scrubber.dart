import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:music_are/core/theme/theme_extension.dart';
import 'package:music_are/features/player/presentation/cubit/player_cubit.dart';
import 'package:music_are/features/player/presentation/cubit/player_state.dart';

class PlayerScrubber extends StatefulWidget {
  final PlayerState state;

  const PlayerScrubber({super.key, required this.state});

  @override
  State<PlayerScrubber> createState() => _PlayerScrubberState();
}

class _PlayerScrubberState extends State<PlayerScrubber> {
  double? _dragSeekMs;

  @override
  Widget build(BuildContext context) {
    final state = widget.state;
    final currentSliderVal = (_dragSeekMs ?? state.positionMs).clamp(0.0, state.maxSlider);

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        SliderTheme(
          data: SliderTheme.of(context).copyWith(
            trackHeight: 4,
            thumbShape: const RoundSliderThumbShape(
              enabledThumbRadius: 6,
            ),
            overlayShape: const RoundSliderOverlayShape(
              overlayRadius: 14,
            ),
            activeTrackColor: context.colorScheme.primary,
            inactiveTrackColor: context.colorScheme.onSurfaceVariant.withValues(alpha: 0.25),
            thumbColor: context.colorScheme.primary,
          ),
          child: Slider(
            value: state.durationMs > 0 ? currentSliderVal : 0.0,
            max: state.maxSlider,
            onChanged: state.durationMs > 0 ? (val) => setState(() => _dragSeekMs = val) : null,
            onChangeEnd: (val) {
              context.read<PlayerCubit>().seek(Duration(milliseconds: val.toInt()));
              setState(() => _dragSeekMs = null);
            },
          ),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 6.0),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                _dragSeekMs != null
                    ? PlayerState.formatDuration(Duration(milliseconds: _dragSeekMs!.toInt()))
                    : state.formattedPosition,
                style: context.textTheme.labelSmall,
              ),
              Text(
                state.formattedDuration,
                style: context.textTheme.labelSmall,
              ),
            ],
          ),
        ),
      ],
    );
  }
}
