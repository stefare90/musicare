import 'package:flutter/material.dart';
import 'package:gyawun_metadata_sdk/metadata/models/artist.dart';
import 'package:music_are/core/l10n/l10n_extension.dart';
import 'package:music_are/core/models/media_type.dart';
import 'package:music_are/core/router/app_navigator.dart';
import 'package:music_are/core/theme/theme_extension.dart';
import 'package:music_are/core/widgets/bottom_sheets/base_modal_bottom_sheet.dart';
import 'package:music_are/core/widgets/media/media_cover_image.dart';

class ArtistSelectionBottomSheet extends StatelessWidget {
  final List<Artist> artists;
  final VoidCallback? onSelected;

  const ArtistSelectionBottomSheet({
    super.key,
    required this.artists,
    this.onSelected,
  });

  static Future<void> show(
    BuildContext context,
    List<Artist> artists, {
    VoidCallback? onSelected,
  }) {
    return BaseModalBottomSheet.show(
      context: context,
      child: ArtistSelectionBottomSheet(
        artists: artists,
        onSelected: onSelected,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return BaseModalBottomSheet(
      title: context.l10n.selectArtistTitle,
      subtitle: '(${artists.length})',
      icon: Icons.person_rounded,
      initialChildSize: 0.45,
      minChildSize: 0.3,
      maxChildSize: 0.75,
      builder: (context, scrollController) {
        return ListView.builder(
          controller: scrollController,
          padding: const EdgeInsets.symmetric(vertical: 8.0),
          itemCount: artists.length,
          itemBuilder: (context, index) {
            final artist = artists[index];
            return ListTile(
              leading: MediaCoverImage(
                images: artist.images,
                mediaType: MediaType.artist,
                width: 44,
                height: 44,
                borderRadius: BorderRadius.circular(22),
              ),
              title: Text(
                artist.name,
                style: context.textTheme.titleSmall,
              ),
              trailing: const Icon(Icons.arrow_forward_ios_rounded, size: 14),
              onTap: () {
                Navigator.of(context).pop();
                onSelected?.call();
                AppNavigator.toArtistDetail(context, artist);
              },
            );
          },
        );
      },
    );
  }
}
