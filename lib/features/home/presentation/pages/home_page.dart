import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:music_are/core/di/injection.dart';
import 'package:music_are/core/l10n/l10n_extension.dart';
import 'package:music_are/core/router/app_navigator.dart';
import 'package:music_are/core/widgets/dialogs.dart';
import 'package:music_are/core/widgets/error_card.dart';
import 'package:music_are/core/widgets/info_card.dart';
import 'package:music_are/core/widgets/media/section_row.dart';
import 'package:music_are/features/home/presentation/cubit/home_cubit.dart';
import 'package:music_are/features/home/presentation/cubit/home_state.dart';
import 'package:music_are/features/plugin/data/services/plugin_engine.dart';
import 'package:music_are/features/plugin/presentation/utils/exception_localizer.dart';

class HomePage extends StatelessWidget {
  const HomePage({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider<HomeCubit>(
      create: (context) => HomeCubit(sl<PluginEngine>())..fetchSections(),
      child: const _HomeView(),
    );
  }
}

class _HomeView extends StatelessWidget {
  const _HomeView();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(context.l10n.appTitle)),
      body: BlocConsumer<HomeCubit, HomeState>(
        listenWhen: (previous, current) =>
            current is HomeLoadedState && current.refreshError != null,
        listener: (context, state) {
          if (state is HomeLoadedState && state.refreshError != null) {
            Dialogs.showErrorSnackBar(
              context,
              message: state.refreshError!.toLocalizedString(context),
            );
          }
        },
        builder: (context, state) {
          if (state is HomeLoadingState) {
            return const Center(child: CircularProgressIndicator());
          }
          if (state is HomeErrorState) {
            return Center(
              child: ErrorCard(
                error: state.error,
                onRetry: () => context.read<HomeCubit>().fetchSections(),
              ),
            );
          }
          if (state is HomeLoadedState) {
            if (state.sections.isEmpty) {
              return RefreshIndicator(
                onRefresh: () => context.read<HomeCubit>().fetchSections(),
                child: SingleChildScrollView(
                  physics: const AlwaysScrollableScrollPhysics(),
                  child: SizedBox(
                    height: MediaQuery.of(context).size.height * 0.7,
                    child: Center(
                      child: InfoCard(
                        title: context.l10n.noContentTitle,
                        message: context.l10n.noContentSubtitle,
                        actionLabel: context.l10n.retry,
                        onAction: () =>
                            context.read<HomeCubit>().fetchSections(),
                      ),
                    ),
                  ),
                ),
              );
            }
            return RefreshIndicator(
              onRefresh: () => context.read<HomeCubit>().fetchSections(),
              child: ListView.builder(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.symmetric(vertical: 16.0),
                itemCount: state.sections.length,
                itemBuilder: (context, index) {
                  final sectionData = state.sections[index];
                  return SectionRow(
                    title: sectionData.section.title,
                    description: sectionData.section.description,
                    items: sectionData.items,
                    onItemTap: (item) =>
                        AppNavigator.toMediaDetail(context, item),
                  );
                },
              ),
            );
          }
          return const SizedBox.shrink();
        },
      ),
    );
  }
}
