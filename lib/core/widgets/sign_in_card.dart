import 'package:flutter/material.dart';
import 'package:music_are/core/l10n/l10n_extension.dart';
import 'package:music_are/core/widgets/info_card.dart';

/// Invites the user to sign in to an account-gated content area.
///
/// A normal state, not an error: it shares [InfoCard]'s visual language and has
/// a fixed "Sign in" action, so there is no label to pass at each call site.
class SignInCard extends StatelessWidget {
  final VoidCallback? onSignIn;
  final String? title;
  final String? message;
  final EdgeInsetsGeometry? margin;

  const SignInCard({
    super.key,
    this.onSignIn,
    this.title,
    this.message,
    this.margin,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;

    return InfoCard(
      icon: Icons.person_outline,
      title: title ?? l10n.authRequiredTitle,
      message: message ?? l10n.authRequiredMessage,
      actionLabel: l10n.authFormSubmit,
      onAction: onSignIn,
      margin: margin ?? const EdgeInsets.all(16.0),
    );
  }
}
