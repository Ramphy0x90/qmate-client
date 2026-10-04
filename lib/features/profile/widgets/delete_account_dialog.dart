import 'package:material_ui/material_ui.dart';

/// Explains what deletion does and collects the password; pops with the
/// password, or null on cancel.
class DeleteAccountDialog extends StatefulWidget {
  const DeleteAccountDialog({super.key, this.error});

  /// Shown when a previous attempt failed (e.g. wrong password).
  final String? error;

  @override
  State<DeleteAccountDialog> createState() => _DeleteAccountDialogState();
}

class _DeleteAccountDialogState extends State<DeleteAccountDialog> {
  final _password = TextEditingController();

  @override
  void dispose() {
    _password.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return AlertDialog(
      title: const Text('Delete your account?'),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Your profile and requests are deleted permanently. Messages you already sent stay visible '
              'to the people you chatted with, shown as from "Deleted user". This can\'t be undone.',
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _password,
              obscureText: true,
              autofocus: true,
              decoration: InputDecoration(
                labelText: 'Confirm with your password',
                errorText: widget.error,
                border: const OutlineInputBorder(),
              ),
              onChanged: (_) => setState(() {}),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
        FilledButton(
          style: FilledButton.styleFrom(backgroundColor: scheme.error, foregroundColor: scheme.onError),
          onPressed: _password.text.isEmpty ? null : () => Navigator.pop(context, _password.text),
          child: const Text('Delete account'),
        ),
      ],
    );
  }
}
