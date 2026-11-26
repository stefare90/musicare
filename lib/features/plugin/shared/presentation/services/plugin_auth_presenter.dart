import 'package:flutter/material.dart';
import 'package:music_are/core/l10n/l10n_extension.dart';
import 'package:music_are/features/plugin/shared/data/exceptions/plugin_exceptions.dart';
import 'package:music_are/features/plugin/shared/presentation/widgets/plugin_auth_form_dialog.dart';
import 'package:musicare_auth_host_sdk/musicare_auth_host_sdk.dart';
import 'package:url_launcher/url_launcher.dart';

class PluginAuthPresenterImpl implements AuthPresenter {
  PluginAuthPresenterImpl({required this.navigatorKey});

  final GlobalKey<NavigatorState> navigatorKey;
  bool _formOpen = false;

  @override
  Future<Map<String, String>?> promptForm({
    String? title,
    String? message,
    required List<FormInputField> fields,
  }) async {
    if (_formOpen) return null;
    final context = navigatorKey.currentContext;
    if (context == null) {
      throw PluginErrorNoContext();
    }

    _formOpen = true;
    try {
      return await showDialog<Map<String, String>>(
        context: context,
        builder: (dialogContext) => PluginAuthFormDialog(
          title: title ?? dialogContext.l10n.authFormTitle,
          message: message,
          fields: fields,
          submitLabel: dialogContext.l10n.authFormSubmit,
          cancelLabel: dialogContext.l10n.cancel,
          onHelpTap: _tryOpenBrowser,
        ),
      );
    } finally {
      _formOpen = false;
    }
  }

  @override
  Future<void> openBrowser(String url) async {
    if (!await _tryOpenBrowser(url)) {
      throw UnsupportedError(
        'Could not open the URL in the system browser (url: $url).',
      );
    }
  }

  Future<bool> _tryOpenBrowser(String url) async {
    final uri = Uri.tryParse(url);
    if (uri == null || !uri.hasScheme) {
      return false;
    }
    try {
      return await launchUrl(uri, mode: LaunchMode.externalApplication);
    } on Exception {
      return false;
    }
  }
}
