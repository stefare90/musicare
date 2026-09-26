import 'package:flutter/material.dart';
import 'package:music_are/core/l10n/l10n_extension.dart';
import 'package:music_are/core/theme/theme_extension.dart';
import 'package:musicare_metadata_host_sdk/musicare_metadata_host_sdk.dart';

class DynamicPluginFormDialog extends StatefulWidget {
  final String title;
  final String? message;
  final List<FormInputField> fields;
  final String submitLabel;
  final String cancelLabel;

  /// Called when the user taps a field's help link; returns whether the URL was
  /// opened. The host owns the launch (the dialog has no `url_launcher` dependency).
  final Future<bool> Function(String url)? onHelpTap;

  const DynamicPluginFormDialog({
    super.key,
    required this.title,
    this.message,
    required this.fields,
    required this.submitLabel,
    required this.cancelLabel,
    this.onHelpTap,
  });

  @override
  State<DynamicPluginFormDialog> createState() =>
      _DynamicPluginFormDialogState();
}

class _DynamicPluginFormDialogState extends State<DynamicPluginFormDialog> {
  final _formKey = GlobalKey<FormState>();
  final Map<String, String> _formData = {};

  @override
  void initState() {
    super.initState();
    for (final field in widget.fields) {
      if (field.defaultValue != null) {
        _formData[field.id] = field.defaultValue!;
      }
    }
  }

  Future<void> _onHelpTap(String url) async {
    final opened = await widget.onHelpTap?.call(url) ?? false;
    if (opened || !mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(context.l10n.authFormHelpFailed)),
    );
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(widget.title),
      content: SingleChildScrollView(
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              if (widget.message != null && widget.message!.isNotEmpty) ...[
                Text(widget.message!, style: context.textTheme.bodyMedium),
                const SizedBox(height: 16),
              ],
              ...widget.fields.map((field) {
                final helpUrl = field.helpUrl;
                return Padding(
                  padding: const EdgeInsets.symmetric(vertical: 8.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      TextFormField(
                        initialValue: field.defaultValue,
                        obscureText: field.isPassword,
                        decoration: InputDecoration(
                          labelText: field.label,
                          hintText: field.placeholder,
                          border: const OutlineInputBorder(),
                        ),
                        onSaved: (value) {
                          _formData[field.id] = value ?? '';
                        },
                      ),
                      if (helpUrl != null && helpUrl.isNotEmpty)
                        Align(
                          alignment: Alignment.centerRight,
                          child: TextButton.icon(
                            onPressed: () => _onHelpTap(helpUrl),
                            icon: const Icon(Icons.open_in_new, size: 18),
                            label: Text(context.l10n.authFormHelpAction),
                          ),
                        ),
                    ],
                  ),
                );
              }),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () {
            Navigator.of(context).pop();
          },
          child: Text(widget.cancelLabel),
        ),
        ElevatedButton(
          onPressed: () {
            if (_formKey.currentState?.validate() ?? false) {
              _formKey.currentState?.save();
              Navigator.of(context).pop(_formData);
            }
          },
          child: Text(widget.submitLabel),
        ),
      ],
    );
  }
}
