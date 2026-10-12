import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:musicare_metadata_host_sdk/musicare_metadata_host_sdk.dart';
import 'package:music_are/core/di/injection.dart';
import 'package:music_are/core/l10n/l10n_extension.dart';
import 'package:music_are/core/notice/notice_bus.dart';
import 'package:music_are/features/player/presentation/cubit/player_cubit.dart';
import 'package:music_are/features/plugin/shared/presentation/utils/notice.dart';

abstract class CollectionActions {
  static Future<void> playAllNext(
    BuildContext context, {
    required Future<List<Track>?> Function() loadAll,
    required int total,
  }) => _enqueue(context, loadAll: loadAll, total: total, next: true);

  static Future<void> addAllToQueue(
    BuildContext context, {
    required Future<List<Track>?> Function() loadAll,
    required int total,
  }) => _enqueue(context, loadAll: loadAll, total: total, next: false);

  static Future<void> _enqueue(
    BuildContext context, {
    required Future<List<Track>?> Function() loadAll,
    required int total,
    required bool next,
  }) async {
    sl<NoticeBus>().emit(Notice.message(context.l10n.addingTracks(total)));
    late final List<Track>? tracks;
    try {
      tracks = await loadAll();
    } catch (e) {
      if (!context.mounted) return;
      sl<NoticeBus>().emit(
        e.needsNotice
            ? Notice.error(e)
            : Notice.message(context.l10n.failedToQueueTracks),
      );
      return;
    }
    if (tracks == null || !context.mounted) return;
    final player = context.read<PlayerCubit>();
    if (next) {
      player.insertAllNext(tracks);
      sl<NoticeBus>().emit(
        Notice.message(context.l10n.addedTracksToPlayNext(tracks.length)),
      );
    } else {
      player.addAllToQueue(tracks);
      sl<NoticeBus>().emit(
        Notice.message(context.l10n.addedTracksToQueue(tracks.length)),
      );
    }
  }
}
