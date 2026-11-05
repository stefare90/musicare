import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:music_are/core/l10n/l10n_extension.dart';
import 'package:music_are/core/router/app_routes.dart';
import 'package:music_are/core/theme/theme_extension.dart';
import 'package:music_are/core/widgets/dialogs.dart';
import 'package:music_are/features/plugin/management/presentation/cubit/plugin_manager_cubit.dart';
import 'package:music_are/features/plugin/management/presentation/cubit/plugin_manager_state.dart';
import 'package:music_are/features/plugin/management/presentation/widgets/plugin_setup_slot.dart';
import 'package:music_are/features/plugin/shared/presentation/cubit/plugin_session_cubit.dart';
import 'package:music_are/features/plugin/shared/data/models/plugin_type.dart';

class PluginSetupPage extends StatefulWidget {
  const PluginSetupPage({super.key});

  @override
  State<PluginSetupPage> createState() => _PluginSetupPageState();
}

class _PluginSetupPageState extends State<PluginSetupPage> {
  @override
  void initState() {
    super.initState();
    if (_isReady(context.read<PluginSessionCubit>().state)) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) context.go(AppRoutes.home);
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final pending = PluginType.values
        .where((type) => !context.watch<PluginSessionCubit>().isLoaded(type))
        .toList();

    return Scaffold(
      body: SafeArea(
        child: MultiBlocListener(
          listeners: [
            BlocListener<PluginManagerCubit, PluginManagerState>(
              listenWhen: (previous, next) =>
                  _isBusy(previous) != _isBusy(next),
              listener: (context, state) {
                if (_isBusy(state)) {
                  Dialogs.showLoading(context, message: l10n.installingPlugin);
                } else {
                  Dialogs.hide(context);
                }
              },
            ),
            BlocListener<PluginSessionCubit, PluginSessionState>(
              listenWhen: (previous, next) => PluginType.values.any(
                (type) =>
                    previous.stateOf(type).status != next.stateOf(type).status,
              ),
              listener: (context, state) {
                if (_isReady(state)) context.go(AppRoutes.home);
              },
            ),
          ],
          child: pending.isEmpty
              ? const SizedBox.shrink()
              : Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Padding(
                      padding: const EdgeInsets.fromLTRB(20.0, 24.0, 20.0, 8.0),
                      child: Text(
                        l10n.actionRequiredTitle,
                        textAlign: TextAlign.center,
                        style: context.textTheme.headlineMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    Expanded(
                      child: SingleChildScrollView(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 20.0,
                          vertical: 16.0,
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            for (var i = 0; i < pending.length; i++)
                              PluginSetupSlot(
                                type: pending[i],
                                index: i + 1,
                                total: pending.length,
                              ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
        ),
      ),
    );
  }

  static bool _isReady(PluginSessionState state) =>
      PluginType.values.every((type) => state.stateOf(type).isLoaded);

  static bool _isBusy(PluginManagerState state) => PluginType.values.any(
    (type) => state.slot(type).phase == PluginSlotPhase.busy,
  );
}
