import 'package:material_ui/material_ui.dart';

import '../../../core/api_client.dart';
import '../../../core/legal.dart';
import '../../../core/session.dart';
import '../../../shared/widgets/legal_links.dart';
import '../widgets/delete_account_dialog.dart';
import '../widgets/profile_view.dart';

/// The signed-in user's own profile. Read-only in v1 (editing is a stretch
/// goal), plus log out, account deletion and the legal pages.
class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key, required this.api, required this.session});

  final ApiClient api;
  final Session session;

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  bool _deleting = false;

  Future<void> _logOut() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Log out?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancel')),
          FilledButton(onPressed: () => Navigator.pop(context, true), child: const Text('Log out')),
        ],
      ),
    );
    if (confirmed == true) await widget.session.signOut();
  }

  Future<void> _deleteAccount() async {
    String? error;
    // Re-prompt on a wrong password instead of dumping the user back out.
    while (true) {
      if (!mounted) return;
      final password = await showDialog<String>(
        context: context,
        builder: (_) => DeleteAccountDialog(error: error),
      );
      if (password == null || !mounted) return;
      setState(() => _deleting = true);
      try {
        await widget.api.deleteAccount(password);
        // Router redirects to login once the session clears.
        await widget.session.signOut();
        return;
      } on ApiException catch (e) {
        error = e.statusCode == 401 ? 'Wrong password.' : e.message;
      } finally {
        if (mounted) setState(() => _deleting = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final user = widget.session.user;
    final scheme = Theme.of(context).colorScheme;
    return Scaffold(
      appBar: AppBar(title: const Text('Profile')),
      body: user == null
          ? const Center(child: CircularProgressIndicator())
          : ProfileView(
              profile: user,
              actions: [
                OutlinedButton.icon(onPressed: _logOut, icon: const Icon(Icons.logout), label: const Text('Log out')),
                const SizedBox(height: 8),
                TextButton.icon(
                  style: TextButton.styleFrom(foregroundColor: scheme.error),
                  onPressed: _deleting ? null : _deleteAccount,
                  icon: const Icon(Icons.delete_forever_outlined),
                  label: const Text('Delete account'),
                ),
                const SizedBox(height: 16),
                Center(
                  child: LegalLinks(
                    onOpenTerms: () => openLegalPage(context, termsUrl),
                    onOpenPrivacy: () => openLegalPage(context, privacyPolicyUrl),
                  ),
                ),
              ],
            ),
    );
  }
}
