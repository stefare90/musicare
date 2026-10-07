import 'package:flutter/material.dart';
import 'package:musicare_metadata_host_sdk/musicare_metadata_host_sdk.dart';
import 'package:music_are/core/models/section_state.dart';
import 'package:music_are/core/widgets/error_card.dart';
import 'package:music_are/core/widgets/info_card.dart';
import 'package:music_are/core/widgets/scrollable_centered.dart';

/// The four states of a paginated section (loading, error, empty, content).
/// [contentBuilder] gets the full result to choose between grid and list.
class SectionSlot<T extends Object> extends StatelessWidget {
  final SectionState<PaginatedResult<T>> section;
  final WidgetBuilder loadingBuilder;
  final Widget Function(BuildContext context, PaginatedResult<T> result)
  contentBuilder;
  final String emptyTitle;
  final String? emptyMessage;
  final IconData emptyIcon;
  final VoidCallback onRetry;

  const SectionSlot({
    super.key,
    required this.section,
    required this.loadingBuilder,
    required this.contentBuilder,
    required this.emptyTitle,
    this.emptyMessage,
    required this.emptyIcon,
    required this.onRetry,
  });

  @override
  Widget build(BuildContext context) {
    final items = section.data.items;
    if (section.error != null && items.isEmpty) {
      return ScrollableCentered(
        child: ErrorCard(error: section.error!, onRetry: onRetry),
      );
    }
    if (section.isLoading && items.isEmpty) {
      return loadingBuilder(context);
    }
    if (items.isEmpty) {
      return ScrollableCentered(
        child: InfoCard(
          title: emptyTitle,
          message: emptyMessage,
          icon: emptyIcon,
        ),
      );
    }
    return contentBuilder(context, section.data);
  }
}
