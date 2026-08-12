import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:music_are/core/l10n/l10n_extension.dart';

abstract class Dialogs {
  static const String _loadingDialogRouteName = 'loading_dialog';

  static void showLoading(BuildContext context, {required String message}) {
    showDialog<void>(
      context: context,
      barrierDismissible: false,
      routeSettings: const RouteSettings(name: _loadingDialogRouteName),
      builder: (dialogContext) {
        return PopScope(
          canPop: false,
          child: AlertDialog(
            content: Row(
              children: [
                const CircularProgressIndicator(),
                const SizedBox(width: 20),
                Expanded(child: Text(message)),
              ],
            ),
          ),
        );
      },
    );
  }

  static void hide(BuildContext context) {
    final navigator = Navigator.of(context, rootNavigator: true);
    bool isLoadingDialogOnTop = false;

    navigator.popUntil((route) {
      if (route.settings.name == _loadingDialogRouteName) {
        isLoadingDialogOnTop = true;
      }
      return true;
    });

    if (isLoadingDialogOnTop) {
      navigator.pop();
    }
  }

  static Future<bool> confirm(
    BuildContext context, {
    required String title,
    required String message,
    String? confirmLabel,
    String? cancelLabel,
  }) async {
    final result = await showDialog<bool>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: Text(title),
          content: Text(message),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(false),
              child: Text(cancelLabel ?? context.l10n.cancel),
            ),
            ElevatedButton(
              onPressed: () => Navigator.of(dialogContext).pop(true),
              child: Text(confirmLabel ?? context.l10n.confirm),
            ),
          ],
        );
      },
    );
    return result ?? false;
  }

  static Future<void> showInfo(
    BuildContext context, {
    required String title,
    required String message,
    IconData? icon,
    Color? iconColor,
    String? primaryLabel,
    IconData? primaryIcon,
    VoidCallback? onPrimaryAction,
    String? secondaryLabel,
    IconData? secondaryIcon,
    VoidCallback? onSecondaryAction,
  }) async {
    final theme = Theme.of(context);
    final effectiveIconColor = iconColor ?? theme.colorScheme.primary;

    return showDialog<void>(
      context: context,
      builder: (dialogContext) {
        final l10n = context.l10n;
        return AlertDialog(
          title: Row(
            children: [
              if (icon != null) ...[
                Icon(icon, color: effectiveIconColor),
                const SizedBox(width: 8),
              ],
              Expanded(
                child: Text(
                  title,
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
          content: SingleChildScrollView(
            child: SelectableText(message, style: theme.textTheme.bodyMedium),
          ),
          actions: [
            if (secondaryLabel != null)
              secondaryIcon != null
                  ? TextButton.icon(
                      onPressed: () {
                        onSecondaryAction?.call();
                        Navigator.of(dialogContext).pop();
                      },
                      icon: Icon(secondaryIcon, size: 18),
                      label: Text(secondaryLabel),
                    )
                  : TextButton(
                      onPressed: () {
                        onSecondaryAction?.call();
                        Navigator.of(dialogContext).pop();
                      },
                      child: Text(secondaryLabel),
                    ),
            primaryIcon != null
                ? ElevatedButton.icon(
                    onPressed: () {
                      onPrimaryAction?.call();
                      Navigator.of(dialogContext).pop();
                    },
                    icon: Icon(primaryIcon, size: 18),
                    label: Text(primaryLabel ?? l10n.ok),
                  )
                : ElevatedButton(
                    onPressed: () {
                      onPrimaryAction?.call();
                      Navigator.of(dialogContext).pop();
                    },
                    child: Text(primaryLabel ?? l10n.ok),
                  ),
          ],
        );
      },
    );
  }

  static Future<void> showError(
    BuildContext context, {
    required String title,
    required Object error,
  }) async {
    final fullErrorDetails = error.toString().replaceAll('Exception: ', '');
    final l10n = context.l10n;
    return showInfo(
      context,
      icon: Icons.bug_report_outlined,
      iconColor: Theme.of(context).colorScheme.error,
      title: l10n.logErrorTitle(title),
      message: fullErrorDetails,
      primaryLabel: l10n.ok,
      secondaryLabel: l10n.copyError,
      secondaryIcon: Icons.copy_rounded,
      onSecondaryAction: () {
        Clipboard.setData(ClipboardData(text: fullErrorDetails));
        Dialogs.showSnackBar(context, message: l10n.errorCopiedToClipboard);
      },
    );
  }

  static void showErrorSnackBar(
    BuildContext context, {
    required String message,
  }) {
    final theme = Theme.of(context);
    ScaffoldMessenger.of(context).hideCurrentSnackBar();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        behavior: SnackBarBehavior.floating,
        margin: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 16.0),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12.0),
        ),
        backgroundColor: theme.colorScheme.surfaceContainerHigh,
        content: Row(
          children: [
            Icon(Icons.error_outline_rounded, color: theme.colorScheme.error),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                message,
                style: TextStyle(color: theme.colorScheme.onSurface),
              ),
            ),
          ],
        ),
      ),
    );
  }

  static void showSnackBar(BuildContext context, {required String message}) {
    ScaffoldMessenger.of(context).hideCurrentSnackBar();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), behavior: SnackBarBehavior.floating),
    );
  }
}
