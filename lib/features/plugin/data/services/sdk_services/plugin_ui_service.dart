import 'package:flutter/material.dart';
import 'package:gyawun_metadata_sdk/metadata/interfaces/iui_service.dart';
import 'package:gyawun_metadata_sdk/metadata/models/form_input_field.dart';
import 'package:music_are/features/plugin/data/exceptions/plugin_engine_exceptions.dart';

class PluginUiService implements IUIService {
  final GlobalKey<NavigatorState> _navigatorKey;

  PluginUiService({required this._navigatorKey});

  BuildContext? get _currentContext => _navigatorKey.currentContext;

  @override
  Future<Map<String, String>> showForm({
    required String title,
    String? message,
    required List<FormInputField> fields,
    String submitLabel = "Confirm",
    String cancelLabel = "Cancel",
  }) async {
    final context = _currentContext;
    if (context == null || !context.mounted) {
      throw NavigationContextUnavailableException();
    }

    final result = await showDialog<Map<String, String>>(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) {
        return DynamicPluginFormDialog(
          title: title,
          message: message,
          fields: fields,
          submitLabel: submitLabel,
          cancelLabel: cancelLabel,
        );
      },
    );

    return result ?? <String, String>{};
  }
}

class DynamicPluginFormDialog extends StatefulWidget {
  final String title;
  final String? message;
  final List<FormInputField> fields;
  final String submitLabel;
  final String cancelLabel;

  const DynamicPluginFormDialog({
    super.key,
    required this.title,
    this.message,
    required this.fields,
    required this.submitLabel,
    required this.cancelLabel,
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
                Text(
                  widget.message!,
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
                const SizedBox(height: 16),
              ],
              ...widget.fields.map((field) {
                return Padding(
                  padding: const EdgeInsets.symmetric(vertical: 8.0),
                  child: TextFormField(
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
                );
              }),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () {
            Navigator.of(context).pop(<String, String>{});
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
