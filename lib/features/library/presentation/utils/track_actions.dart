import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:musicare_metadata_host_sdk/musicare_metadata_host_sdk.dart';
import 'package:music_are/core/di/injection.dart';
import 'package:music_are/core/l10n/l10n_extension.dart';
import 'package:music_are/core/notice/notice_bus.dart';
import 'package:music_are/core/widgets/bottom_sheets/track_options_bottom_sheet.dart';
import 'package:music_are/features/plugin/metadata/presentation/cubit/user_cubit.dart';
import 'package:music_are/features/library/presentation/widgets/add_to_playlist_bottom_sheet.dart';
import 'package:music_are/features/player/presentation/cubit/player_cubit.dart';

abstract class TrackActions {
  static Future<void> showOptions(
    BuildContext context,
    Track track, {
    VoidCallback? onBeforeNavigate,
  }) {
    final saved = context.read<UserCubit>();

    return TrackOptionsBottomSheet.show(
      context,
      track,
      isSaved: saved.isTrackSaved(track.id),
      onAddToQueue: () => _addToQueue(context, track),
      onToggleFavorite: () => saved.toggleTrack(track),
      onAddToPlaylist: () => AddToPlaylistBottomSheet.show(context, track),
      onBeforeNavigate: onBeforeNavigate,
    );
  }

  static void _addToQueue(BuildContext context, Track track) {
    context.read<PlayerCubit>().addToQueue(track);
    sl<NoticeBus>().emit(Notice.message(context.l10n.addedToQueue));
  }
}
