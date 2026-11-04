import 'package:flutter/material.dart';
import 'package:music_are/core/l10n/l10n_extension.dart';
import 'package:music_are/core/widgets/monogram.dart';
import 'package:music_are/features/plugin/shared/data/models/plugin_auth_state.dart';
import 'package:music_are/features/plugin/shared/data/models/plugin_type.dart';
import 'package:music_are/features/plugin/shared/presentation/utils/plugin_account_actions.dart';

class PluginAccountTile extends StatelessWidget {
  final PluginType type;
  final PluginAuthState auth;

  const PluginAccountTile({
    super.key,
    required this.type,
    required this.auth,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final isAuthenticated = auth.isAuthenticated;
    final accountId = auth.accountId;

    return ListTile(
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
              onPressed: () => PluginAccountActions.signOut(context, type),
              child: Text(l10n.accountSignOut),
            )
          : FilledButton(
              onPressed: () => PluginAccountActions.signIn(context, type),
              child: Text(l10n.accountSignIn),
            ),
    );
  }
}
