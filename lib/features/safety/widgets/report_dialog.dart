import 'package:material_ui/material_ui.dart';

/// Collects a report reason; pops with the trimmed text, or null on cancel.
class ReportDialog extends StatefulWidget {
  const ReportDialog({super.key, required this.displayName});

  final String displayName;

  @override
  State<ReportDialog> createState() => _ReportDialogState();
}

class _ReportDialogState extends State<ReportDialog> {
  final _reason = TextEditingController();

  @override
  void dispose() {
    _reason.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text('Report ${widget.displayName}'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Text('Tell us what happened. Reports are confidential.'),
          const SizedBox(height: 12),
          TextField(
            controller: _reason,
            autofocus: true,
            maxLength: 1000,
            maxLines: 4,
            minLines: 2,
            decoration: const InputDecoration(border: OutlineInputBorder(), hintText: 'Reason'),
            onChanged: (_) => setState(() {}),
          ),
        ],
      ),
      actions: [
        TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
        FilledButton(
          onPressed: _reason.text.trim().isEmpty ? null : () => Navigator.pop(context, _reason.text.trim()),
          child: const Text('Send report'),
        ),
      ],
    );
  }
}
