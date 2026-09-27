import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:music_are/core/l10n/l10n_extension.dart';
import 'package:music_are/core/widgets/dialogs.dart';
import 'package:music_are/features/plugin/metadata/presentation/cubit/metadata_plugin_cubit.dart';

/// Account actions for the metadata plugin.
///
/// The plugin is the only account provider today, so these helpers live next to
/// its cubit instead of in `core`: reusable widgets must stay free of this
/// dependency, and the feature pages already read the same cubit. When the
/// platform exposes `IAuth` for every plugin this moves behind an account port.
abstract class MetadataAccountActions {
  /// Runs the sign-in flow, reporting a real failure with the app's error
  /// snackbar (a cancelled form stays silent). Returns whether the user is now
  /// signed in.
  static Future<bool> signIn(BuildContext context) async {
    final result = await context.read<MetadataPluginCubit>().authenticate();
    if (result == AuthResult.failed && context.mounted) {
      Dialogs.showErrorSnackBar(
        context,
        message: context.l10n.authSignInFailed,
      );
    }
    return result == AuthResult.authenticated;
  }

  static Future<void> signOut(BuildContext context) =>
      context.read<MetadataPluginCubit>().logout();
}
