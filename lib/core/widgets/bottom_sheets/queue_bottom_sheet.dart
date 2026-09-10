import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:music_are/core/l10n/l10n_extension.dart';
import 'package:music_are/core/theme/theme_extension.dart';
import 'package:music_are/core/widgets/bottom_sheets/base_modal_bottom_sheet.dart';
import 'package:music_are/features/player/presentation/cubit/player_cubit.dart';
import 'package:music_are/features/player/presentation/cubit/player_state.dart';
import 'package:music_are/features/player/presentation/widgets/queue_track_tile.dart';

class QueueBottomSheet extends StatelessWidget {
  const QueueBottomSheet({super.key});

  static Future<void> show(BuildContext context) {
    return BaseModalBottomSheet.show(
      context: context,
      child: BlocProvider<PlayerCubit>.value(
        value: context.read<PlayerCubit>(),
        child: const QueueBottomSheet(),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final player = context.read<PlayerCubit>();

    return BlocConsumer<PlayerCubit, PlayerState>(
      listener: (context, state) {
        if (state.queue.isEmpty) {
          final nav = Navigator.of(context, rootNavigator: true);
          if (nav.canPop()) {
            nav.pop();
          }
        }
      },
      builder: (context, state) {
        final queue = state.queue;
        final tracks = queue.tracks;

        return BaseModalBottomSheet(
          title: context.l10n.playbackQueue,
          subtitle: '(${tracks.length})',
          initialChildSize: 0.65,
          minChildSize: 0.4,
          maxChildSize: 0.92,
          builder: (context, scrollController) {
            if (tracks.isEmpty) {
              return Center(
                child: Text(
                  context.l10n.queueEmpty,
                  style: context.textTheme.bodyMedium,
                ),
              );
            }

            return ReorderableListView.builder(
              scrollController: scrollController,
              padding: const EdgeInsets.symmetric(vertical: 8.0),
              itemCount: tracks.length,
              onReorderItem: (oldIndex, newIndex) {
                player.reorderQueue(oldIndex, newIndex);
              },
              itemBuilder: (context, index) {
                final track = tracks[index];
                final isPlaying = index == queue.currentIndex;

                return QueueTrackTile(
                  key: ValueKey('queue_item_${track.id}_$index'),
                  track: track,
                  index: index,
                  isPlaying: isPlaying,
                  onTap: () => player.skipToIndex(index),
                  onDismissed: () => player.removeFromQueue(index),
                );
              },
            );
          },
        );
      },
    );
  }
}
