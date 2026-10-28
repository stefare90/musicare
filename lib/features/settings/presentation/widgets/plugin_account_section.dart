import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:music_are/core/l10n/l10n_extension.dart';
import 'package:music_are/core/widgets/monogram.dart';
import 'package:music_are/features/plugin/presentation/cubit/plugin_session_cubit.dart';
import 'package:music_are/features/plugin/shared/data/capabilities/plugin_lifecycle.dart';
import 'package:music_are/features/plugin/shared/data/models/plugin_auth_state.dart';
import 'package:music_are/features/plugin/shared/data/models/plugin_type.dart';
import 'package:music_are/features/plugin/shared/presentation/utils/plugin_account_actions.dart';
import 'package:music_are/features/settings/presentation/widgets/settings_section_header.dart';

class PluginAccountSection extends StatelessWidget {
  final PluginType type;

  const PluginAccountSection({super.key, required this.type});

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;

    return BlocBuilder<PluginSessionCubit, PluginSessionState>(
      builder: (context, pluginState) {
        final plugins = context.read<PluginSessionCubit>();
        if (!plugins.hasAuth(type) ||
            pluginState.stateOf(type).status != PluginLifecycleStatus.loaded) {
          return const SizedBox.shrink();
        }

        final auth = pluginState.authOf(type);
        if (auth.status == PluginAuthStatus.unavailable) {
          return const SizedBox.shrink();
        }
        final isAuthenticated = auth.isAuthenticated;
        final accountId = auth.accountId;

        return Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            SettingsSectionHeader(label: l10n.pluginAccountSection),
            ListTile(
              leading: auth.status == PluginAuthStatus.loading
                  ? const SizedBox.square(
                      dimension: 40.0,
                      child: Center(child: CircularProgressIndicator()),
                    )
                  : Monogram(name: accountId, radius: 20.0),
              title: Text(
                isAuthenticated
                    ? (accountId?.isNotEmpty == true
                          ? accountId!
                          : l10n.accountSignedIn)
                    : l10n.accountNotSignedIn,
              ),
              trailing: isAuthenticated
                  ? TextButton(
                      onPressed: () =>
                          PluginAccountActions.signOut(context, type),
                      child: Text(l10n.accountSignOut),
                    )
                  : FilledButton(
                      onPressed: () =>
                          PluginAccountActions.signIn(context, type),
                      child: Text(l10n.accountSignIn),
                    ),
            ),
          ],
        );
      },
    );
  }
}
