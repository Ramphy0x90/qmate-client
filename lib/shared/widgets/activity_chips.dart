import 'package:material_ui/material_ui.dart';

import '../../core/models.dart';

IconData activityIcon(ActivityType type) => switch (type) {
  ActivityType.gaming => Icons.sports_esports_outlined,
  ActivityType.hangout => Icons.local_cafe_outlined,
  ActivityType.walk => Icons.directions_walk,
  ActivityType.movieNight => Icons.movie_outlined,
  ActivityType.study => Icons.menu_book_outlined,
};

/// Single-select activity chips. With [allLabel] set, a leading chip selects
/// `null` (used as the "All" filter on Discover).
class ActivityChips extends StatelessWidget {
  const ActivityChips({
    super.key,
    required this.selected,
    required this.onSelected,
    this.allLabel,
    this.scrollable = false,
  });

  final ActivityType? selected;
  final ValueChanged<ActivityType?> onSelected;
  final String? allLabel;
  final bool scrollable;

  @override
  Widget build(BuildContext context) {
    final chips = [
      if (allLabel != null)
        ChoiceChip(label: Text(allLabel!), selected: selected == null, onSelected: (_) => onSelected(null)),
      for (final type in ActivityType.values)
        ChoiceChip(
          avatar: Icon(activityIcon(type), size: 18),
          label: Text(type.label),
          selected: selected == type,
          onSelected: (_) => onSelected(type),
        ),
    ];
    if (!scrollable) return Wrap(spacing: 8, runSpacing: 4, children: chips);
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Row(
        children: [for (final c in chips) Padding(padding: const EdgeInsets.only(right: 8), child: c)],
      ),
    );
  }
}
