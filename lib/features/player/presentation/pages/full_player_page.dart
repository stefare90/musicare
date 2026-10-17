import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:music_are/core/models/media_type.dart';
import 'package:music_are/core/theme/theme_extension.dart';
import 'package:music_are/core/widgets/media/cover_backdrop.dart';
import 'package:music_are/features/library/presentation/utils/track_actions.dart';
import 'package:music_are/features/player/presentation/cubit/player_cubit.dart';
import 'package:music_are/features/player/presentation/cubit/player_state.dart';
import 'package:music_are/features/player/presentation/widgets/full_player_landscape_view.dart';
import 'package:music_are/features/player/presentation/widgets/full_player_portrait_view.dart';

class FullPlayerPage extends StatelessWidget {
  final VoidCallback? onCollapse;

  const FullPlayerPage({super.key, this.onCollapse});

  @override
  Widget build(BuildContext context) {
    return BlocConsumer<PlayerCubit, PlayerState>(
      listener: (context, state) {
        if (state.currentTrack == null) {
          onCollapse?.call();
        }
      },
      builder: (context, state) {
        final track = state.currentTrack;
        if (track == null) {
          return Scaffold(
            backgroundColor: context.colorScheme.surface,
            appBar: AppBar(
              backgroundColor: Colors.transparent,
              elevation: 0,
              leading: IconButton(
                icon: const Icon(Icons.keyboard_arrow_down_rounded, size: 32),
                onPressed: () => onCollapse?.call(),
              ),
            ),
            body: const SizedBox.shrink(),
          );
        }

        return Scaffold(
          backgroundColor: context.colorScheme.surface,
          appBar: AppBar(
            backgroundColor: Colors.transparent,
            elevation: 0,
            leading: IconButton(
              icon: const Icon(Icons.keyboard_arrow_down_rounded, size: 32),
              onPressed: () => onCollapse?.call(),
            ),
            actions: [
              IconButton(
                icon: const Icon(Icons.more_vert_rounded),
                onPressed: () => TrackActions.showOptions(
                  context,
                  track,
                  onBeforeNavigate: onCollapse,
                ),
              ),
            ],
          ),
          body: LayoutBuilder(
            builder: (context, constraints) {
              final isLandscape = constraints.maxWidth > constraints.maxHeight;
              return Stack(
                children: [
                  Positioned.fill(
                    child: CoverBackdrop(
                      images: track.album.images,
                      mediaType: MediaType.track,
                      background: context.colorScheme.surface,
                      haloCenter: isLandscape
                          ? const Alignment(-0.3, 0.0)
                          : const Alignment(0.0, -0.3),
                      haloRadius: 0.85,
                      haloScaleY: 0.9,
                    ),
                  ),
                  SafeArea(
                    child: isLandscape
                        ? FullPlayerLandscapeView(
                            track: track,
                            state: state,
                            onCollapse: onCollapse,
                          )
                        : FullPlayerPortraitView(
                            track: track,
                            state: state,
                            onCollapse: onCollapse,
                          ),
                  ),
                ],
              );
            },
          ),
        );
      },
    );
  }
}
