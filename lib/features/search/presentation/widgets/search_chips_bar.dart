import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:musicare_metadata_host_sdk/musicare_metadata_host_sdk.dart';
import 'package:music_are/core/l10n/l10n_extension.dart';
import 'package:music_are/core/theme/theme_extension.dart';
import 'package:music_are/features/search/presentation/cubit/search_cubit.dart';
import 'package:music_are/features/search/presentation/cubit/search_state.dart';

class SearchChipsBar extends StatelessWidget {
  const SearchChipsBar({super.key});

  @override
  Widget build(BuildContext context) {
    final scheme = context.colorScheme;

    return BlocBuilder<SearchCubit, SearchState>(
      buildWhen: (prev, curr) =>
          prev.chips != curr.chips || prev.selectedChip != curr.selectedChip,
      builder: (context, state) {
        final categories = <SearchCategory?>[null, ...state.chips];

        return SizedBox(
          height: 48.0,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(
              horizontal: 16.0,
              vertical: 6.0,
            ),
            itemCount: categories.length,
            separatorBuilder: (context, index) => const SizedBox(width: 8.0),
            itemBuilder: (context, index) {
              final category = categories[index];
              final isSelected = category == state.selectedChip;

              return FilterChip(
                label: Text(_categoryLabel(context, category)),
                selected: isSelected,
                showCheckmark: false,
                side: BorderSide.none,
                backgroundColor: scheme.primary.withValues(alpha: 0.15),
                selectedColor: scheme.primary,
                labelStyle: TextStyle(
                  color: isSelected ? scheme.onPrimary : scheme.onSurface,
                ),
                onSelected: (_) =>
                    context.read<SearchCubit>().selectChip(category),
              );
            },
          ),
        );
      },
    );
  }
}

String _categoryLabel(BuildContext context, SearchCategory? category) {
  switch (category) {
    case null:
      return context.l10n.searchAllChip;
    case SearchCategory.tracks:
      return context.l10n.searchTracksHeader;
    case SearchCategory.albums:
      return context.l10n.searchAlbumsHeader;
    case SearchCategory.artists:
      return context.l10n.searchArtistsHeader;
    case SearchCategory.playlists:
      return context.l10n.searchPlaylistsHeader;
  }
}
