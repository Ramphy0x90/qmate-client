import 'package:material_ui/material_ui.dart';
import 'package:url_launcher/url_launcher.dart';

import 'config.dart';

// The policy pages are served by qmate-server (legal/*.html), so they're
// always the same text the store listings link to.
final privacyPolicyUrl = Uri.parse('$apiBaseUrl/legal/privacy');
final termsUrl = Uri.parse('$apiBaseUrl/legal/terms');

/// Opens a policy page in the browser; shows a snackbar if that fails.
Future<void> openLegalPage(BuildContext context, Uri url) async {
  final opened = await launchUrl(url, mode: LaunchMode.externalApplication);
  if (!opened && context.mounted) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Couldn't open $url")));
  }
}
