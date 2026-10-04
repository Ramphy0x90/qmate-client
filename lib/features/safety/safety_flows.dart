import 'package:material_ui/material_ui.dart';

import '../../core/api_client.dart';
import 'widgets/report_dialog.dart';

// Block and report flows, shared by the chat and user-profile screens. These
// are screen-level helpers (dialogs + API calls), not widgets.

/// Confirms, then blocks. Returns true if the user is now blocked.
Future<bool> confirmAndBlock(
  BuildContext context,
  ApiClient api, {
  required String userId,
  required String displayName,
}) async {
  final confirmed = await showDialog<bool>(
    context: context,
    builder: (context) => AlertDialog(
      title: Text('Block $displayName?'),
      content: const Text(
        "They won't see your requests or profile, and any chat between you is closed. They aren't told.",
      ),
      actions: [
        TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancel')),
        FilledButton(
          style: FilledButton.styleFrom(backgroundColor: Theme.of(context).colorScheme.error),
          onPressed: () => Navigator.pop(context, true),
          child: const Text('Block'),
        ),
      ],
    ),
  );
  if (confirmed != true || !context.mounted) return false;
  try {
    await api.block(userId);
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('$displayName is blocked.')));
    }
    return true;
  } on ApiException catch (e) {
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.message)));
    }
    return false;
  }
}

/// Collects a reason and files a report. Then offers to block as well, since
/// most people reporting someone don't want to hear from them again.
/// Returns true if the user ended up blocked.
Future<bool> reportUser(
  BuildContext context,
  ApiClient api, {
  required String userId,
  required String displayName,
}) async {
  final reason = await showDialog<String>(
    context: context,
    builder: (_) => ReportDialog(displayName: displayName),
  );
  if (reason == null || !context.mounted) return false;
  try {
    await api.report(userId, reason);
  } on ApiException catch (e) {
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.message)));
    }
    return false;
  }
  if (!context.mounted) return false;
  ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Thanks — we'll review your report.")));
  return confirmAndBlock(context, api, userId: userId, displayName: displayName);
}
