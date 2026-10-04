import 'package:material_ui/material_ui.dart';

import '../../../core/models.dart';
import '../../../shared/format.dart';
import '../../../shared/widgets/activity_chips.dart';
import '../../../shared/widgets/initials_avatar.dart';

class MatchTile extends StatelessWidget {
  const MatchTile({super.key, required this.match, required this.onTap});

  final MatchView match;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final other = match.otherUser;
    return ListTile(
      onTap: onTap,
      leading: other == null
          ? const CircleAvatar(child: Icon(Icons.person_off_outlined))
          : InitialsAvatar(name: other.displayName, photoUrl: other.photoUrl),
      title: Text(match.otherName),
      subtitle: Row(
        children: [
          Icon(activityIcon(match.activityType), size: 16),
          const SizedBox(width: 4),
          Expanded(
            child: Text(
              '${match.activityType.label} · matched ${timeAgo(match.createdAt)}',
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
      trailing: const Icon(Icons.chevron_right),
    );
  }
}
