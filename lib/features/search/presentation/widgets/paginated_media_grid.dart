import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:music_are/core/router/app_navigator.dart';
import 'package:music_are/core/widgets/media/media_card.dart';
import 'package:music_are/core/widgets/media/media_card_metrics.dart';
import 'package:music_are/core/widgets/skeletons/shimmer_box.dart';
import 'package:music_are/features/search/presentation/cubit/search_cubit.dart';

class PaginatedMediaGrid extends StatelessWidget {
  final List<Object> items;
  final bool hasMore;
  final bool isLoadingMore;

  const PaginatedMediaGrid({
    super.key,
    required this.items,
    required this.hasMore,
    required this.isLoadingMore,
  });

  @override
  Widget build(BuildContext context) {
    return NotificationListener<ScrollNotification>(
      onNotification: (scrollInfo) {
        if (hasMore && !isLoadingMore && scrollInfo.metrics.extentAfter < 200) {
          context.read<SearchCubit>().loadMore();
        }
        return false;
      },
      child: LayoutBuilder(
        builder: (context, constraints) {
          final textBlockHeight = MediaCardMetrics.textBlockHeight(context);
          final delegate = MediaCardMetrics.gridDelegate(
            maxWidth: constraints.maxWidth,
            textBlockHeight: textBlockHeight,
          );
          final columns = delegate.crossAxisCount;
          final cellWidth = MediaCardMetrics.gridCellWidth(
            constraints.maxWidth,
            columns,
          );
          final cellHeight = cellWidth + textBlockHeight;
          // A whole row of skeletons keeps the progressive loading coherent
          // with the initial grid skeleton instead of showing a lone spinner.
          final skeletonCount = isLoadingMore ? columns : 0;

          return GridView.builder(
            padding: const EdgeInsets.all(MediaCardMetrics.edgeInset),
            gridDelegate: delegate,
            itemCount: items.length + skeletonCount,
            itemBuilder: (context, index) {
              if (index >= items.length) {
                return ShimmerBox(
                  width: cellWidth,
                  height: cellHeight,
                  borderRadius: BorderRadius.circular(MediaCardMetrics.radius),
                );
              }
              final item = items[index];
              return MediaCard(
                item: item,
                onTap: () => AppNavigator.toMediaDetail(context, item),
              );
            },
          );
        },
      ),
    );
  }
}
