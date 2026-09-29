import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:music_are/core/l10n/l10n_extension.dart';
import 'package:music_are/core/theme/theme_extension.dart';
import 'package:music_are/features/search/presentation/cubit/search_cubit.dart';

class SearchField extends StatelessWidget {
  final TextEditingController controller;
  final FocusNode focusNode;

  const SearchField({
    super.key,
    required this.controller,
    required this.focusNode,
  });

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: controller,
      focusNode: focusNode,
      textInputAction: TextInputAction.search,
      decoration: InputDecoration(
        hintText: context.l10n.searchHint,
        prefixIcon: const Icon(Icons.search),
        suffixIcon: ValueListenableBuilder<TextEditingValue>(
          valueListenable: controller,
          builder: (context, value, _) {
            if (value.text.isEmpty) return const SizedBox.shrink();
            return IconButton(
              icon: const Icon(Icons.clear),
              onPressed: () {
                controller.clear();
                context.read<SearchCubit>().onQueryChanged('');
              },
            );
          },
        ),
        isDense: true,
        filled: true,
        fillColor: context.colorScheme.surfaceContainerHighest.withValues(
          alpha: 0.5,
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(28.0),
          borderSide: BorderSide.none,
        ),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 16.0,
          vertical: 10.0,
        ),
      ),
      onChanged: (text) {
        context.read<SearchCubit>().onQueryChanged(text);
      },
      onSubmitted: (text) {
        context.read<SearchCubit>().search(text);
      },
    );
  }
}
