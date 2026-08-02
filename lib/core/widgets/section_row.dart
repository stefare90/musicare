import 'package:flutter/material.dart';
import 'package:music_are/core/theme/theme_extension.dart';
import 'package:music_are/core/widgets/section_item_card.dart';

class SectionRow extends StatelessWidget {
  final String title;
  final String? description;
  final List<dynamic> items;
  final void Function(dynamic item)? onItemTap;

  const SectionRow({
    super.key,
    required this.title,
    this.description,
    required this.items,
    this.onItemTap,
  });

  @override
  Widget build(BuildContext context) {
    if (items.isEmpty) return const SizedBox.shrink();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(title, style: context.textTheme.titleLarge),
              if (description != null && description!.isNotEmpty) ...[
                const SizedBox(height: 4),
                Text(description!, style: context.textTheme.bodyMedium),
              ],
            ],
          ),
        ),
        SizedBox(
          height: 212,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 10.0),
            itemCount: items.length,
            itemBuilder: (context, index) {
              final item = items[index];
              return SectionItemCard(
                item: item,
                onTap: onItemTap != null ? () => onItemTap!(item) : null,
              );
            },
          ),
        ),
        const SizedBox(height: 16),
      ],
    );
  }
}
