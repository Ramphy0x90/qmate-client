import 'package:material_ui/material_ui.dart';

class LegalLinks extends StatelessWidget {
  const LegalLinks({super.key, required this.onOpenTerms, required this.onOpenPrivacy});

  final VoidCallback onOpenTerms;
  final VoidCallback onOpenPrivacy;

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 4,
      children: [
        TextButton(onPressed: onOpenTerms, child: const Text('Terms of Use')),
        TextButton(onPressed: onOpenPrivacy, child: const Text('Privacy Policy')),
      ],
    );
  }
}
