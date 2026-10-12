import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:music_are/core/l10n/l10n_extension.dart';
import 'package:music_are/core/theme/theme_extension.dart';
import 'package:music_are/core/widgets/bottom_sheets/base_modal_bottom_sheet.dart';
import 'package:music_are/features/player/presentation/cubit/player_cubit.dart';
import 'package:music_are/features/player/presentation/cubit/pending_state.dart';
import 'package:music_are/features/player/presentation/cubit/player_state.dart';
import 'package:music_are/features/player/presentation/widgets/queue_track_tile.dart';
import 'package:music_are/features/plugin/shared/presentation/utils/exception_localizer.dart';
import 'package:music_are/core/widgets/skeletons/skeleton_track_list.dart';

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

            final pending = state.pending;
            final hasFooter =
                pending.error != null ||
                (pending.isLoading && pending.remaining > 0);
            final list = ReorderableListView.builder(
              scrollController: scrollController,
              padding: const EdgeInsets.symmetric(vertical: 8.0),
              itemCount: tracks.length + (hasFooter ? 1 : 0),
              buildDefaultDragHandles: false,
              onReorderItem: (oldIndex, newIndex) {
                player.reorderQueue(oldIndex, newIndex);
              },
              itemBuilder: (context, index) {
                if (index == tracks.length) {
                  return _pendingFooter(context, player, pending);
                }
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
            return list;
          },
        );
      },
    );
  }
}

Widget _pendingFooter(
  BuildContext context,
  PlayerCubit player,
  PendingState pending,
) {
  final error = pending.error;
  if (error != null) {
    return Padding(
      key: const ValueKey('queue_pending_error'),
      padding: const EdgeInsets.fromLTRB(16.0, 4.0, 8.0, 12.0),
      child: Row(
        children: [
          Expanded(child: Text(error.toLocalizedString(context))),
          TextButton(
            onPressed: () => player.retryPendingLoad(),
            child: Text(context.l10n.retry),
          ),
        ],
      ),
    );
  }
  return const Padding(
    key: ValueKey('queue_pending_loading'),
    padding: EdgeInsets.only(top: 4.0, bottom: 12.0),
    child: SkeletonTrackList(count: 1, showDuration: false),
  );
}
