import 'package:material_ui/material_ui.dart';

import '../../../core/models.dart';
import '../../../shared/widgets/initials_avatar.dart';
import '../../../shared/widgets/label_chips.dart';

/// Read-only profile body, used for both "me" and other users. [actions] is
/// rendered below the content (sign out, or block/report).
class ProfileView extends StatelessWidget {
  const ProfileView({super.key, required this.profile, this.actions = const []});

  final Profile profile;
  final List<Widget> actions;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final muted = theme.textTheme.bodyMedium?.copyWith(color: theme.colorScheme.onSurfaceVariant);
    return ListView(
      padding: const EdgeInsets.all(24),
      children: [
        Center(
          child: InitialsAvatar(name: profile.displayName, photoUrl: profile.photoUrl, radius: 44),
        ),
        const SizedBox(height: 12),
        Center(child: Text(profile.displayName, style: theme.textTheme.headlineSmall)),
        Center(child: Text('@${profile.username}', style: muted)),
        const SizedBox(height: 24),
        Text('About', style: theme.textTheme.titleSmall),
        const SizedBox(height: 4),
        Text(profile.bio.isEmpty ? 'No bio yet.' : profile.bio, style: profile.bio.isEmpty ? muted : null),
        const SizedBox(height: 20),
        Text('Vibe', style: theme.textTheme.titleSmall),
        const SizedBox(height: 6),
        profile.roleTags.isEmpty
            ? Text('None picked.', style: muted)
            : LabelChips(labels: profile.roleTags.map((t) => t.label).toList()),
        const SizedBox(height: 20),
        Text('Enjoys', style: theme.textTheme.titleSmall),
        const SizedBox(height: 6),
        profile.activityPrefs.isEmpty
            ? Text('None picked.', style: muted)
            : LabelChips(labels: profile.activityPrefs.map((a) => a.label).toList()),
        if (actions.isNotEmpty) ...[const SizedBox(height: 32), ...actions],
      ],
    );
  }
}
