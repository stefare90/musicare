import 'package:flutter/material.dart';
import 'package:gyawun_metadata_sdk/metadata/models/track.dart';
import 'package:music_are/core/router/app_navigator.dart';
import 'package:music_are/core/theme/theme_extension.dart';
import 'package:music_are/core/widgets/bottom_sheets/artist_selection_bottom_sheet.dart';

class PlayerTrackInfo extends StatelessWidget {
  final Track track;
  final VoidCallback? onCollapse;
  final bool isCentered;

  const PlayerTrackInfo({
    super.key,
    required this.track,
    this.onCollapse,
    this.isCentered = true,
  });

  void _onArtistsTap(BuildContext context) {
    if (track.artists.isEmpty) return;
    if (track.artists.length == 1) {
      onCollapse?.call();
      AppNavigator.toArtistDetail(context, track.artists.first);
      return;
    }

    ArtistSelectionBottomSheet.show(
      context,
      track.artists,
      onSelected: onCollapse,
    );
  }

  @override
  Widget build(BuildContext context) {
    final artistNames = track.artists.map((a) => a.name).join(', ');

    final titleWidget = SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      physics: const BouncingScrollPhysics(),
      child: Text(
        track.name,
        textAlign: isCentered ? TextAlign.center : TextAlign.start,
        style: context.textTheme.headlineMedium?.copyWith(
          color: context.colorScheme.primary,
        ),
      ),
    );

    final artistWidget = artistNames.isNotEmpty
        ? GestureDetector(
            onTap: () => _onArtistsTap(context),
            child: Text(
              artistNames,
              textAlign: isCentered ? TextAlign.center : TextAlign.start,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: context.textTheme.titleMedium?.copyWith(
                color: context.colorScheme.onSurfaceVariant,
              ),
            ),
          )
        : const SizedBox.shrink();

    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: isCentered
          ? CrossAxisAlignment.center
          : CrossAxisAlignment.start,
      children: [
        isCentered ? Center(child: titleWidget) : titleWidget,
        const SizedBox(height: 6),
        isCentered ? Center(child: artistWidget) : artistWidget,
      ],
    );
  }
}
