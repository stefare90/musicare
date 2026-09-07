import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:music_are/core/models/media_type.dart';
import 'package:music_are/core/theme/theme_extension.dart';
import 'package:music_are/core/widgets/media/media_cover_image.dart';
import 'package:music_are/features/player/presentation/cubit/player_cubit.dart';
import 'package:music_are/features/player/presentation/cubit/player_state.dart';
import 'package:music_are/features/player/presentation/pages/full_player_page.dart';

class MiniPlayer extends StatelessWidget {
  final VoidCallback? onExpand;

  const MiniPlayer({super.key, this.onExpand});

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<PlayerCubit, PlayerState>(
      buildWhen: (prev, curr) =>
          prev.currentTrack?.id != curr.currentTrack?.id ||
          prev.status != curr.status ||
          prev.hasNext != curr.hasNext,
      builder: (context, state) {
        final track = state.currentTrack;
        if (track == null) {
          return const SizedBox.shrink();
        }

        final artistNames = track.artists.map((a) => a.name).join(', ');

        return SizedBox(
          width: double.infinity,
          child: Material(
            color: context.colorScheme.surfaceContainerHigh,
            child: InkWell(
              onTap: onExpand ?? () => FullPlayerPage.show(context),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const _MiniPlayerProgressBar(),
                  Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12.0,
                      vertical: 6.0,
                    ),
                    child: Row(
                      children: [
                        MediaCoverImage(
                          images: track.album.images,
                          mediaType: MediaType.track,
                          width: 44,
                          height: 44,
                          borderRadius: BorderRadius.circular(6),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(
                                track.name,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: context.textTheme.titleMedium?.copyWith(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                              if (artistNames.isNotEmpty)
                                Text(
                                  artistNames,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: context.textTheme.labelSmall?.copyWith(
                                    color: context.colorScheme.onSurfaceVariant,
                                  ),
                                ),
                            ],
                          ),
                        ),
                        if (state.isLoading)
                          const SizedBox(
                            width: 40,
                            height: 40,
                            child: Padding(
                              padding: EdgeInsets.all(10.0),
                              child: CircularProgressIndicator(
                                strokeWidth: 2.5,
                              ),
                            ),
                          )
                        else
                          IconButton(
                            icon: Icon(
                              state.isPlaying
                                  ? Icons.pause_rounded
                                  : Icons.play_arrow_rounded,
                              size: 30,
                            ),
                            onPressed: () =>
                                context.read<PlayerCubit>().togglePlayPause(),
                          ),
                        IconButton(
                          icon: const Icon(Icons.skip_next_rounded, size: 28),
                          onPressed: state.hasNext
                              ? () => context.read<PlayerCubit>().next()
                              : null,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}

class _MiniPlayerProgressBar extends StatelessWidget {
  const _MiniPlayerProgressBar();

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
            height: 2.0,
            child: LinearProgressIndicator(
              value: progress,
              backgroundColor: Colors.transparent,
              valueColor: AlwaysStoppedAnimation<Color>(
                context.colorScheme.primary,
              ),
            ),
          ),
        );
      },
    );
  }
}
