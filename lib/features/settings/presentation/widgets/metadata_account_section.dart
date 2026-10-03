import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:music_are/core/l10n/l10n_extension.dart';
import 'package:music_are/core/widgets/monogram.dart';
import 'package:music_are/features/plugin/metadata/presentation/cubit/account_cubit.dart';
import 'package:music_are/features/plugin/metadata/presentation/cubit/account_state.dart';
import 'package:music_are/features/plugin/metadata/presentation/cubit/metadata_plugin_cubit.dart';
import 'package:music_are/features/plugin/metadata/presentation/cubit/metadata_plugin_state.dart';
import 'package:music_are/features/plugin/metadata/presentation/utils/metadata_account_actions.dart';
import 'package:music_are/features/settings/presentation/widgets/settings_section_header.dart';

/// Account section of the metadata plugin: identity and the sign in/out action.
class MetadataAccountSection extends StatelessWidget {
  const MetadataAccountSection({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;

    return BlocBuilder<MetadataPluginCubit, MetadataPluginState>(
      builder: (context, pluginState) {
        if (pluginState is! MetadataPluginLoadedState) {
          return const SizedBox.shrink();
        }

        return BlocBuilder<AccountCubit, AccountState>(
          builder: (context, auth) {
            final isAuthenticated = auth.isAuthenticated;
            final userId = auth.userId;

            return Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                SettingsSectionHeader(label: l10n.pluginAccountSection),
                ListTile(
                  leading: Monogram(name: userId, radius: 20.0),
                  title: Text(
                    isAuthenticated
                        ? (userId ?? l10n.accountSignedIn)
                        : l10n.accountNotSignedIn,
                  ),
                  trailing: isAuthenticated
                      ? TextButton(
                          onPressed: () => MetadataAccountActions.signOut(
                            context,
                          ),
                          child: Text(l10n.accountSignOut),
                        )
                      : FilledButton(
                          onPressed: () => MetadataAccountActions.signIn(
                            context,
                          ),
                          child: Text(l10n.accountSignIn),
                        ),
                ),
              ],
            );
          },
        );
      },
    );
  }
}
