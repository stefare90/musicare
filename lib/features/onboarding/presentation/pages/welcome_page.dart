import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:music_are/core/l10n/l10n_extension.dart';
import 'package:music_are/core/theme/theme_extension.dart';
import 'package:music_are/core/widgets/dialogs.dart';
import 'package:music_are/features/plugin/presentation/cubit/plugin_cubit.dart';
import 'package:music_are/features/plugin/presentation/cubit/plugin_state.dart';
import 'package:music_are/features/plugin/presentation/widgets/plugin_discovery_widget.dart';

class WelcomePage extends StatelessWidget {
  const WelcomePage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: BlocListener<PluginCubit, PluginState>(
          listener: (context, state) {
            if (state is PluginLoadingState) {
              Dialogs.showLoading(
                context,
                message: context.l10n.installingPlugin,
              );
            } else if (state is PluginLoadedState) {
              Dialogs.hide(context);
              context.go('/');
            } else if (state is PluginErrorState) {
              Dialogs.hide(context);
              Dialogs.showErrorSnackBar(context, message: state.message);
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
                Icon(
                  Icons.graphic_eq,
                  size: 200,
                  color: context.colorScheme.primary,
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
                const PluginDiscoveryWidget(),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
