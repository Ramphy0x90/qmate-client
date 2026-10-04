import 'package:material_ui/material_ui.dart';

/// Profile photo if there is one, otherwise the user's initials. There's no
/// photo upload in v1, so in practice this is nearly always initials.
class InitialsAvatar extends StatelessWidget {
  const InitialsAvatar({super.key, required this.name, this.photoUrl, this.radius = 20});

  final String name;
  final String? photoUrl;
  final double radius;

  String get _initials {
    final parts = name.trim().split(RegExp(r'\s+')).where((p) => p.isNotEmpty);
    return parts.take(2).map((p) => p.characters.first.toUpperCase()).join();
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final url = photoUrl;
    return CircleAvatar(
      radius: radius,
      backgroundColor: scheme.primaryContainer,
      foregroundColor: scheme.onPrimaryContainer,
      foregroundImage: url == null ? null : NetworkImage(url),
      child: Text(_initials, style: TextStyle(fontSize: radius * 0.8)),
    );
  }
}
