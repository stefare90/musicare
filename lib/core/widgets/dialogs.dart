import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:music_are/core/l10n/l10n_extension.dart';
import 'package:music_are/core/theme/theme_extension.dart';

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
    final effectiveIconColor = iconColor ?? context.colorScheme.primary;

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
                  style: context.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
          content: SingleChildScrollView(
            child: SelectableText(message, style: context.textTheme.bodyMedium),
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
      iconColor: context.colorScheme.error,
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
    String? actionLabel,
    VoidCallback? onAction,
    double keyboardInset = 0.0,
  }) => _showSnackBar(
    context,
    message: message,
    icon: Icons.error_outline_rounded,
    iconColor: context.colorScheme.error,
    actionLabel: actionLabel,
    onAction: onAction,
    keyboardInset: keyboardInset,
  );

  static void showMessageSnackBar(
    BuildContext context, {
    required String message,
    String? actionLabel,
    VoidCallback? onAction,
    double keyboardInset = 0.0,
  }) => _showSnackBar(
    context,
    message: message,
    actionLabel: actionLabel,
    onAction: onAction,
    keyboardInset: keyboardInset,
  );

  static void _showSnackBar(
    BuildContext context, {
    required String message,
    IconData? icon,
    Color? iconColor,
    String? actionLabel,
    VoidCallback? onAction,
    // Non-zero only when the on-screen Scaffold does not lift the snackbar
    // for the keyboard itself.
    double keyboardInset = 0.0,
  }) {
    ScaffoldMessenger.of(context).hideCurrentSnackBar();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        behavior: SnackBarBehavior.floating,
        margin: EdgeInsets.only(
          left: 16.0,
          right: 16.0,
          bottom: 16.0 + keyboardInset,
        ),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12.0),
          side: BorderSide(color: context.colorScheme.primary, width: 1.2),
        ),
        backgroundColor: context.colorScheme.surfaceContainerHigh,
        persist: false,
        action: actionLabel != null && onAction != null
            ? SnackBarAction(
                label: actionLabel,
                textColor: context.colorScheme.primary,
                onPressed: onAction,
              )
            : null,
        content: Row(
          children: [
            if (icon != null) ...[
              Icon(icon, color: iconColor ?? context.colorScheme.error),
              const SizedBox(width: 12),
            ],
            Expanded(
              child: Text(
                message,
                style: TextStyle(color: context.colorScheme.onSurface),
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
