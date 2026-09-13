import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:gyawun_metadata_sdk/metadata/models/track.dart';
import 'package:music_are/core/l10n/l10n_extension.dart';
import 'package:music_are/core/theme/theme_extension.dart';
import 'package:music_are/core/widgets/bottom_sheets/base_modal_bottom_sheet.dart';
import 'package:music_are/features/player/presentation/cubit/player_cubit.dart';
import 'package:music_are/features/player/presentation/cubit/player_state.dart';

class AudioSourceBottomSheet extends StatelessWidget {
  final Track track;

  const AudioSourceBottomSheet({super.key, required this.track});

  static Future<void> show(BuildContext context, Track track) {
    return BaseModalBottomSheet.show(
      context: context,
      child: BlocProvider<PlayerCubit>.value(
        value: context.read<PlayerCubit>(),
        child: AudioSourceBottomSheet(track: track),
      ),
    );
  }

  String _formatDuration(int? durationMs) {
    if (durationMs == null || durationMs <= 0) return '';
    return PlayerState.formatDuration(Duration(milliseconds: durationMs));
  }

  @override
  Widget build(BuildContext context) {
    final player = context.read<PlayerCubit>();

    return BlocBuilder<PlayerCubit, PlayerState>(
      builder: (context, state) {
        final candidates = state.candidates;
        final candidateList = candidates.candidates;
        final activeCandidateId = candidates.activeCandidateId;

        return BaseModalBottomSheet(
          title: context.l10n.audioStreamCandidates,
          subtitle: context.l10n.availableStreamsCount(candidateList.length),
          icon: Icons.graphic_eq_rounded,
          initialChildSize: 0.55,
          minChildSize: 0.35,
          maxChildSize: 0.85,
          builder: (context, scrollController) {
            if (candidateList.isEmpty) {
              return Center(
                child: Text(
                  context.l10n.pluginErrorStreamResolution,
                  style: context.textTheme.bodyMedium,
                ),
              );
            }

            return ListView.builder(
              controller: scrollController,
              padding: const EdgeInsets.symmetric(vertical: 8.0),
              itemCount: candidateList.length,
              itemBuilder: (context, index) {
                final candidate = candidateList[index];
                final isSelected = candidate.id == activeCandidateId;

                final subtitleParts = <String>[];
                if (candidate.artist != null && candidate.artist!.isNotEmpty) {
                  subtitleParts.add(candidate.artist!);
                }
                final durFormatted = _formatDuration(candidate.durationMs);
                if (durFormatted.isNotEmpty) {
                  subtitleParts.add(durFormatted);
                }
                final subtitle = subtitleParts.join(' • ');

                return Material(
                  color: isSelected
                      ? context.colorScheme.primary.withValues(alpha: 0.12)
                      : Colors.transparent,
                  child: ListTile(
                    onTap: () {
                      player.selectStreamCandidate(index);
                      Navigator.of(context).pop();
                    },
                    leading: Container(
                      width: 44,
                      height: 44,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: isSelected
                            ? context.colorScheme.primary.withValues(alpha: 0.2)
                            : context.colorScheme.surfaceContainerHighest,
                      ),
                      child: Icon(
                        isSelected
                            ? Icons.check_circle_rounded
                            : Icons.play_circle_outline_rounded,
                        color: isSelected
                            ? context.colorScheme.primary
                            : context.colorScheme.onSurfaceVariant,
                      ),
                    ),
                    title: Text(
                      candidate.title,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: context.textTheme.titleSmall?.copyWith(
                        color: isSelected ? context.colorScheme.primary : null,
                        fontWeight: isSelected
                            ? FontWeight.bold
                            : FontWeight.w500,
                      ),
                    ),
                    subtitle: subtitle.isNotEmpty
                        ? Text(
                            subtitle,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: context.textTheme.labelSmall,
                          )
                        : null,
                    trailing: isSelected
                        ? Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 3,
                            ),
                            decoration: BoxDecoration(
                              color: context.colorScheme.primary,
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: Text(
                              context.l10n.activeLabel,
                              style: context.textTheme.labelSmall?.copyWith(
                                color: context.colorScheme.onPrimary,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          )
                        : null,
                  ),
                );
              },
            );
          },
        );
      },
    );
  }
}
