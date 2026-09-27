import 'package:flutter/material.dart';
import 'package:music_are/core/widgets/error_card.dart';
import 'package:music_are/core/widgets/sign_in_card.dart';
import 'package:music_are/features/plugin/metadata/presentation/utils/metadata_account_actions.dart';
import 'package:musicare_metadata_host_sdk/musicare_metadata_host_sdk.dart';

/// Presents a failed metadata-plugin request to the user.
///
/// This is the single place that classifies `auth_required`: it becomes a
/// [SignInCard] wired to the plugin sign-in (always the same action, derived
/// here), every other error becomes an [ErrorCard]. Callers only pass what is
/// specific to their surface: the retry.
extension PluginStatusCardX on Object {
  Widget toStatusCard(BuildContext context, {VoidCallback? onRetry}) {
    return this is MetadataAuthRequiredException
        ? SignInCard(onSignIn: () => MetadataAccountActions.signIn(context))
        : ErrorCard(error: this, onRetry: onRetry);
  }
}
