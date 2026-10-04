import 'package:material_ui/material_ui.dart';

import '../../../core/models.dart';
import '../../../shared/format.dart';
import '../../../shared/widgets/activity_chips.dart';

class MyRequestTile extends StatelessWidget {
  const MyRequestTile({super.key, required this.request, required this.onCancel, this.busy = false});

  final RequestView request;
  final VoidCallback onCancel;
  final bool busy;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final subtitle = [
      if (request.note.isNotEmpty) request.note,
      if (request.addons.isNotEmpty) request.addons.join(', '),
      timeAgo(request.createdAt),
    ].join('\n');
    return ListTile(
      leading: Icon(activityIcon(request.activityType)),
      title: Text(request.activityType.label),
      subtitle: Text(subtitle),
      isThreeLine: subtitle.contains('\n'),
      trailing: request.status == RequestStatus.open
          ? TextButton(onPressed: busy ? null : onCancel, child: const Text('Cancel'))
          : Text(
              request.status.label,
              style: theme.textTheme.labelLarge?.copyWith(
                color: request.status == RequestStatus.matched
                    ? theme.colorScheme.primary
                    : theme.colorScheme.onSurfaceVariant,
              ),
            ),
    );
  }
}
