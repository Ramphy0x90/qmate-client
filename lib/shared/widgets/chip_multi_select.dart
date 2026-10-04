import 'package:material_ui/material_ui.dart';

/// Wrap of FilterChips over a fixed catalog (role tags, activity prefs, addons).
class ChipMultiSelect<T> extends StatelessWidget {
  const ChipMultiSelect({
    super.key,
    required this.options,
    required this.labelOf,
    required this.selected,
    required this.onChanged,
  });

  final List<T> options;
  final String Function(T) labelOf;
  final Set<T> selected;
  final ValueChanged<Set<T>> onChanged;

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 8,
      runSpacing: 4,
      children: [
        for (final option in options)
          FilterChip(
            label: Text(labelOf(option)),
            selected: selected.contains(option),
            onSelected: (on) => onChanged(on ? {...selected, option} : ({...selected}..remove(option))),
          ),
      ],
    );
  }
}
