import 'package:go_router/go_router.dart';
import 'package:material_ui/material_ui.dart';

import '../../../core/api_client.dart';
import '../../../core/models.dart';
import '../../../core/routes.dart';
import '../../safety/safety_flows.dart';
import '../../../shared/widgets/status_views.dart';
import '../widgets/profile_view.dart';

/// Another user's profile, with block and report.
class UserProfileScreen extends StatefulWidget {
  const UserProfileScreen({super.key, required this.api, required this.userId});

  final ApiClient api;
  final String userId;

  @override
  State<UserProfileScreen> createState() => _UserProfileScreenState();
}

class _UserProfileScreenState extends State<UserProfileScreen> {
  Profile? _profile;
  String? _error;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _error = null);
    try {
      final profile = await widget.api.user(widget.userId);
      if (mounted) setState(() => _profile = profile);
    } on ApiException catch (e) {
      if (!mounted) return;
      setState(() => _error = e.statusCode == 404 ? "This profile isn't available." : e.message);
    }
  }

  /// After a block, everything involving this user disappears, so leave the
  /// whole stack rather than popping back into a now-closed chat.
  void _leave() {
    if (mounted) context.go(Routes.discover);
  }

  Future<void> _block(Profile p) async {
    if (await confirmAndBlock(context, widget.api, userId: p.id, displayName: p.displayName)) _leave();
  }

  Future<void> _report(Profile p) async {
    if (await reportUser(context, widget.api, userId: p.id, displayName: p.displayName)) _leave();
  }

  @override
  Widget build(BuildContext context) {
    final profile = _profile;
    final error = _error;
    final scheme = Theme.of(context).colorScheme;
    return Scaffold(
      appBar: AppBar(),
      body: error != null
          ? ErrorRetry(message: error, onRetry: _load)
          : profile == null
          ? const Center(child: CircularProgressIndicator())
          : ProfileView(
              profile: profile,
              actions: [
                OutlinedButton.icon(
                  onPressed: () => _report(profile),
                  icon: const Icon(Icons.flag_outlined),
                  label: const Text('Report'),
                ),
                const SizedBox(height: 8),
                OutlinedButton.icon(
                  style: OutlinedButton.styleFrom(foregroundColor: scheme.error),
                  onPressed: () => _block(profile),
                  icon: const Icon(Icons.block),
                  label: const Text('Block'),
                ),
              ],
            ),
    );
  }
}
