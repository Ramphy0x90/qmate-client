import 'package:material_ui/material_ui.dart';

import '../../../core/models.dart';
import '../../../shared/format.dart';
import '../../../shared/widgets/activity_chips.dart';
import '../../../shared/widgets/initials_avatar.dart';
import '../../../shared/widgets/label_chips.dart';

/// An open request on Discover. [busy] disables the actions while the screen
/// is accepting/declining.
class RequestCard extends StatelessWidget {
  const RequestCard({
    super.key,
    required this.request,
    required this.onAccept,
    required this.onDecline,
    required this.onAuthorTap,
    this.busy = false,
  });

  final RequestView request;
  final VoidCallback onAccept;
  final VoidCallback onDecline;
  final VoidCallback onAuthorTap;
  final bool busy;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final author = request.author;
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            InkWell(
              onTap: onAuthorTap,
              borderRadius: BorderRadius.circular(8),
              child: Row(
                children: [
                  InitialsAvatar(name: author.displayName, photoUrl: author.photoUrl),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(author.displayName, style: theme.textTheme.titleMedium),
                        Text(
                          '@${author.username} · ${timeAgo(request.createdAt)}',
                          style: theme.textTheme.bodySmall?.copyWith(color: theme.colorScheme.onSurfaceVariant),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Icon(activityIcon(request.activityType), color: theme.colorScheme.primary),
                const SizedBox(width: 8),
                Text(request.activityType.label, style: theme.textTheme.titleSmall),
              ],
            ),
            if (request.note.isNotEmpty) ...[const SizedBox(height: 8), Text(request.note)],
            if (request.addons.isNotEmpty) ...[
              const SizedBox(height: 8),
              LabelChips(labels: request.addons, icon: Icons.favorite_border),
            ],
            if (author.roleTags.isNotEmpty) ...[
              const SizedBox(height: 8),
              Text(
                author.roleTags.map((t) => t.label).join(' · '),
                style: theme.textTheme.bodySmall?.copyWith(color: theme.colorScheme.onSurfaceVariant),
              ),
            ],
            const SizedBox(height: 4),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                TextButton(onPressed: busy ? null : onDecline, child: const Text('Not for me')),
                const SizedBox(width: 8),
                FilledButton(onPressed: busy ? null : onAccept, child: const Text('Accept')),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
