import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:music_are/core/di/injection.dart';
import 'package:music_are/core/l10n/l10n_extension.dart';
import 'package:music_are/core/router/app_navigator.dart';
import 'package:music_are/core/widgets/info_card.dart';
import 'package:music_are/core/widgets/media/section_row.dart';
import 'package:music_are/core/widgets/settings_button.dart';
import 'package:music_are/features/home/presentation/cubit/home_cubit.dart';
import 'package:music_are/features/home/presentation/cubit/home_state.dart';
import 'package:music_are/features/plugin/metadata/data/services/metadata_plugin_engine.dart';
import 'package:music_are/features/plugin/metadata/presentation/cubit/metadata_plugin_cubit.dart';
import 'package:music_are/features/plugin/metadata/presentation/cubit/metadata_plugin_state.dart';
import 'package:music_are/features/plugin/metadata/presentation/utils/plugin_status_card.dart';

class HomePage extends StatelessWidget {
  const HomePage({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider<HomeCubit>(
      create: (context) =>
          HomeCubit(sl<MetadataPluginEngine>())..fetchSections(),
      child: BlocListener<MetadataPluginCubit, MetadataPluginState>(
        listenWhen: (previous, current) =>
            previous.isAuthenticated != current.isAuthenticated,
        listener: (context, state) => context.read<HomeCubit>().fetchSections(),
        child: const _HomeView(),
      ),
    );
  }
}

class _HomeView extends StatelessWidget {
  const _HomeView();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(context.l10n.appTitle),
        actions: const [SettingsButton()],
      ),
      body: BlocBuilder<HomeCubit, HomeState>(
        builder: (context, state) {
          if (state.hasError) {
            return Center(
              child: state.error!.toStatusCard(
                context,
                onRetry: () => context.read<HomeCubit>().fetchSections(),
              ),
            );
          }
          if (state.sections.isEmpty && !state.isLoading) {
            return Center(
              child: InfoCard(
                title: context.l10n.noContentTitle,
                message: context.l10n.noContentSubtitle,
                actionLabel: context.l10n.retry,
                onAction: () => context.read<HomeCubit>().fetchSections(),
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
                  items: sectionData.itemsState.data,
                  isLoading: sectionData.itemsState.isLoading,
                  error: sectionData.itemsState.error,
                  onRetry: () => context.read<HomeCubit>().retrySection(
                    sectionData.section.id,
                  ),
                  onItemTap: (item) =>
                      AppNavigator.toMediaDetail(context, item),
                );
              },
            ),
          );
        },
      ),
    );
  }
}
