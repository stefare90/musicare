import 'package:flutter/material.dart';
import 'package:music_are/core/l10n/l10n_extension.dart';
import 'package:music_are/features/plugin/metadata/presentation/widgets/dynamic_plugin_form_dialog.dart';
import 'package:music_are/features/plugin/shared/data/exceptions/plugin_exceptions.dart';
import 'package:musicare_metadata_host_sdk/musicare_metadata_host_sdk.dart';
import 'package:url_launcher/url_launcher.dart';

class MetadataAuthPresenterImpl implements MetadataAuthPresenter {
  MetadataAuthPresenterImpl({required this._navigatorKey});

  final GlobalKey<NavigatorState> _navigatorKey;

  @override
  Future<Map<String, String>?> promptForm({
    String? title,
    String? message,
    required List<FormInputField> fields,
  }) async {
    final context = _navigatorKey.currentContext;
    if (context == null) {
      throw PluginErrorNoContext();
    }

    return showDialog<Map<String, String>>(
      context: context,
      builder: (dialogContext) => DynamicPluginFormDialog(
        title: title ?? dialogContext.l10n.authFormTitle,
        message: message,
        fields: fields,
        submitLabel: dialogContext.l10n.authFormSubmit,
        cancelLabel: dialogContext.l10n.cancel,
        onHelpTap: _tryOpenBrowser,
      ),
    );
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
