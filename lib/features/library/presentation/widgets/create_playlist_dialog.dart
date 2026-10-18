import 'package:flutter/material.dart';
import 'package:music_are/core/l10n/l10n_extension.dart';

typedef CreatePlaylistResult = ({
  String name,
  String? description,
  bool isPublic,
});

class CreatePlaylistDialog extends StatefulWidget {
  const CreatePlaylistDialog({super.key});

  static Future<CreatePlaylistResult?> show(BuildContext context) {
    FocusManager.instance.primaryFocus?.unfocus();
    return showDialog<CreatePlaylistResult>(
      context: context,
      builder: (_) => const CreatePlaylistDialog(),
    );
  }

  @override
  State<CreatePlaylistDialog> createState() => _CreatePlaylistDialogState();
}

class _CreatePlaylistDialogState extends State<CreatePlaylistDialog> {
  final TextEditingController _name = TextEditingController();
  final TextEditingController _description = TextEditingController();
  bool _isPublic = false;

  @override
  void dispose() {
    _name.dispose();
    _description.dispose();
    super.dispose();
  }

  void _submit() {
    final name = _name.text.trim();
    if (name.isEmpty) return;
    final description = _description.text.trim();
    Navigator.of(context).pop((
      name: name,
      description: description.isEmpty ? null : description,
      isPublic: _isPublic,
    ));
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return AlertDialog(
      scrollable: true,
      title: Text(l10n.newPlaylist),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          TextField(
            controller: _name,
            autofocus: true,
            textCapitalization: TextCapitalization.sentences,
            decoration: InputDecoration(labelText: l10n.playlistNameLabel),
            onSubmitted: (_) => _submit(),
          ),
          const SizedBox(height: 8),
          TextField(
            controller: _description,
            decoration: InputDecoration(
              labelText: l10n.playlistDescriptionLabel,
            ),
          ),
          SwitchListTile(
            value: _isPublic,
            onChanged: (value) => setState(() => _isPublic = value),
            title: Text(l10n.playlistPublicLabel),
            contentPadding: EdgeInsets.zero,
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: Text(l10n.cancel),
        ),
        ValueListenableBuilder(
          valueListenable: _name,
          builder: (context, value, _) => ElevatedButton(
            onPressed: value.text.trim().isEmpty ? null : _submit,
            child: Text(l10n.createPlaylistAction),
          ),
        ),
      ],
    );
  }
}
