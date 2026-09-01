import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:music_are/core/l10n/l10n_extension.dart';
import 'package:music_are/core/theme/theme_extension.dart';
import 'package:music_are/core/widgets/dialogs.dart';
import 'package:music_are/features/plugin/discovery/presentation/widgets/plugin_discovery_widget.dart';
import 'package:music_are/features/plugin/metadata/presentation/cubit/metadata_plugin_cubit.dart';
import 'package:music_are/features/plugin/metadata/presentation/cubit/metadata_plugin_state.dart';
import 'package:music_are/features/plugin/shared/data/models/plugin_type.dart';
import 'package:music_are/features/plugin/shared/presentation/utils/exception_localizer.dart';

class WelcomePage extends StatelessWidget {
  const WelcomePage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: BlocListener<MetadataPluginCubit, MetadataPluginState>(
          listener: (context, state) {
            if (state is MetadataPluginLoadingState) {
              Dialogs.showLoading(
                context,
                message: context.l10n.installingPlugin,
              );
            } else if (state is MetadataPluginLoadedState) {
              Dialogs.hide(context);
              context.go('/');
            } else if (state is MetadataPluginErrorState) {
              Dialogs.hide(context);
              Dialogs.showErrorSnackBar(
                context,
                message: state.error.toLocalizedString(context),
              );
            }
          },
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(
              horizontal: 24.0,
              vertical: 32.0,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const SizedBox(height: 24),
                Center(
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(20),
                    child: Image.asset(
                      'assets/images/app_icon.png',
                      height: 200,
                      width: 200,
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                Text(
                  context.l10n.welcomeTitle,
                  style: context.textTheme.headlineLarge,
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 8),
                Text(
                  context.l10n.appSlogan,
                  style: context.textTheme.titleMedium,
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 12),
                Text(
                  context.l10n.selectProviderSubtitle,
                  style: context.textTheme.bodyMedium,
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 40),
                const PluginDiscoveryWidget(pluginType: PluginType.metadata),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
