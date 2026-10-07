import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:music_are/core/di/injection.dart';
import 'package:music_are/core/l10n/l10n_extension.dart';
import 'package:music_are/core/notice/notice_bus.dart';
import 'package:music_are/core/widgets/settings_button.dart';
import 'package:music_are/features/plugin/metadata/data/repositories/search_repository.dart';
import 'package:music_are/features/search/presentation/cubit/search_cubit.dart';
import 'package:music_are/features/search/presentation/widgets/search_chips_bar.dart';
import 'package:music_are/features/search/presentation/widgets/search_field.dart';
import 'package:music_are/features/search/presentation/widgets/search_results_body.dart';

class SearchPage extends StatelessWidget {
  const SearchPage({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider<SearchCubit>(
      create: (context) =>
          SearchCubit(sl<SearchRepository>(), sl<NoticeBus>())..loadChips(),
      child: const _SearchView(),
    );
  }
}

class _SearchView extends StatefulWidget {
  const _SearchView();

  @override
  State<_SearchView> createState() => _SearchViewState();
}

class _SearchViewState extends State<_SearchView> {
  late final TextEditingController _controller;
  late final FocusNode _focusNode;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController();
    _focusNode = FocusNode();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // The shell keeps every branch mounted and toggles TickerMode: focus the
    // field when Search becomes visible, release it when it is left.
    if (TickerMode.valuesOf(context).enabled) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted &&
            TickerMode.valuesOf(context).enabled &&
            !_focusNode.hasFocus) {
          _focusNode.requestFocus();
        }
      });
    } else if (_focusNode.hasFocus) {
      _focusNode.unfocus();
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      resizeToAvoidBottomInset: false,
      appBar: AppBar(
        titleSpacing: 16.0,
        title: Text(context.l10n.searchTab),
        actions: const [SettingsButton()],
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(104.0),
          child: Column(
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(16.0, 0.0, 16.0, 8.0),
                child: SearchField(
                  controller: _controller,
                  focusNode: _focusNode,
                ),
              ),
              const SearchChipsBar(),
            ],
          ),
        ),
      ),
      body: const SearchResultsBody(),
    );
  }
}
