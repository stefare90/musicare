import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:music_are/core/l10n/l10n_extension.dart';
import 'package:music_are/core/widgets/error_card.dart';
import 'package:music_are/core/widgets/info_card.dart';
import 'package:music_are/core/widgets/media/media_card_metrics.dart';
import 'package:music_are/features/search/presentation/cubit/search_cubit.dart';
import 'package:music_are/features/search/presentation/cubit/search_state.dart';
import 'package:music_are/features/search/presentation/widgets/all_results_view.dart';
import 'package:music_are/features/search/presentation/widgets/category_results_view.dart';
import 'package:music_are/features/search/presentation/widgets/scrollable_centered.dart';
import 'package:music_are/features/search/presentation/widgets/search_loading_view.dart';

class SearchResultsBody extends StatelessWidget {
  const SearchResultsBody({super.key});

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final columns = MediaCardMetrics.gridColumns(constraints.maxWidth);
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (!context.mounted) return;
          context.read<SearchCubit>().updateGridColumns(columns);
        });

        return BlocBuilder<SearchCubit, SearchState>(
          builder: (context, state) {
            if (state.isEmptyQuery) {
              return ScrollableCentered(
                child: InfoCard(
                  title: context.l10n.searchEmptyTitle,
                  message: context.l10n.searchEmptySubtitle,
                  icon: Icons.search,
                ),
              );
            }

            if (state.error != null) {
              return ScrollableCentered(
                child: ErrorCard(
                  error: state.error!,
                  onRetry: () => context.read<SearchCubit>().retry(),
                ),
              );
            }

            if (state.isLoading) {
              return const SearchLoadingView();
            }

            if (!state.hasResults) {
              return ScrollableCentered(
                child: InfoCard(
                  title: context.l10n.searchNoResultsTitle,
                  message: context.l10n.searchNoResultsSubtitle,
                  icon: Icons.music_off,
                ),
              );
            }

            final category = state.selectedChip;
            if (category == null) {
              return AllResultsView(response: state.allResults!);
            }

            return CategoryResultsView(state: state, category: category);
          },
        );
      },
    );
  }
}
