import 'package:material_ui/material_ui.dart';

/// Read-only chips for displaying role tags, prefs or addons.
class LabelChips extends StatelessWidget {
  const LabelChips({super.key, required this.labels, this.icon});

  final List<String> labels;
  final IconData? icon;

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 6,
      runSpacing: 6,
      children: [
        for (final label in labels)
          Chip(
            avatar: icon == null ? null : Icon(icon, size: 16),
            label: Text(label),
            visualDensity: VisualDensity.compact,
            materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
          ),
      ],
    );
  }
}
