import 'package:flutter/material.dart';
import 'package:music_are/core/l10n/l10n_extension.dart';
import 'package:music_are/features/plugin/metadata/presentation/widgets/dynamic_plugin_form_dialog.dart';
import 'package:music_are/features/plugin/shared/data/exceptions/plugin_exceptions.dart';
import 'package:musicare_metadata_host_sdk/musicare_metadata_host_sdk.dart';

/// Host half of the metadata plugin auth flow: renders the provider form and would
/// open OAuth URLs.
class MetadataAuthPresenterImpl implements MetadataAuthPresenter {
  MetadataAuthPresenterImpl({required this._navigatorKey});

  final GlobalKey<NavigatorState> _navigatorKey;

  @override
  Future<Map<String, String>?> promptForm(List<FormInputField> fields) async {
    final context = _navigatorKey.currentContext;
    if (context == null) {
      throw PluginErrorNoContext();
    }

    return showDialog<Map<String, String>>(
      context: context,
      builder: (dialogContext) => DynamicPluginFormDialog(
        title: dialogContext.l10n.authFormTitle,
        fields: fields,
        submitLabel: dialogContext.l10n.authFormSubmit,
        cancelLabel: dialogContext.l10n.cancel,
      ),
    );
  }

  @override
  Future<void> openBrowser(String url) {
    throw UnsupportedError(
      'Opening a browser is not supported: the app has no url_launcher dependency, '
      'and no metadata provider requires an OAuth flow (url: $url).',
    );
  }
}
