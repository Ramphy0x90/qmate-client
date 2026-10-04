import 'package:material_ui/material_ui.dart';

/// Shown above the composer when the live socket isn't connected.
class ConnectionBanner extends StatelessWidget {
  const ConnectionBanner({super.key, required this.message, this.onReconnect});

  final String message;
  final VoidCallback? onReconnect;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Material(
      color: scheme.secondaryContainer,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
        child: Row(
          children: [
            Expanded(
              child: Text(message, style: TextStyle(color: scheme.onSecondaryContainer)),
            ),
            if (onReconnect != null) TextButton(onPressed: onReconnect, child: const Text('Reconnect')),
          ],
        ),
      ),
    );
  }
}
