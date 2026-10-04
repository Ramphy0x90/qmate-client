import 'package:go_router/go_router.dart';
import 'package:material_ui/material_ui.dart';

import '../../../core/api_client.dart';
import '../../../core/models.dart';
import '../../../shared/widgets/activity_chips.dart';
import '../../../shared/widgets/chip_multi_select.dart';
import '../../../shared/widgets/status_views.dart';

/// Pops with `true` once the request is created.
class CreateRequestScreen extends StatefulWidget {
  const CreateRequestScreen({super.key, required this.api});

  final ApiClient api;

  @override
  State<CreateRequestScreen> createState() => _CreateRequestScreenState();
}

class _CreateRequestScreenState extends State<CreateRequestScreen> {
  final _note = TextEditingController();
  List<Addon>? _catalog;
  String? _catalogError;
  ActivityType? _activity;
  Set<Addon> _addons = {};
  bool _busy = false;

  @override
  void initState() {
    super.initState();
    _loadCatalog();
  }

  @override
  void dispose() {
    _note.dispose();
    super.dispose();
  }

  Future<void> _loadCatalog() async {
    setState(() => _catalogError = null);
    try {
      final catalog = await widget.api.addons();
      if (mounted) setState(() => _catalog = catalog);
    } on ApiException catch (e) {
      if (mounted) setState(() => _catalogError = e.message);
    }
  }

  Future<void> _submit() async {
    final activity = _activity;
    if (activity == null) return;
    setState(() => _busy = true);
    try {
      await widget.api.createRequest(
        activityType: activity,
        note: _note.text,
        addonIds: _addons.map((a) => a.id).toList(),
      );
      if (mounted) context.pop(true);
    } on ApiException catch (e) {
      if (!mounted) return;
      setState(() => _busy = false);
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.message)));
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final catalog = _catalog;
    return Scaffold(
      appBar: AppBar(title: const Text('New request')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Text('What do you want to do?', style: theme.textTheme.titleSmall),
          const SizedBox(height: 8),
          ActivityChips(selected: _activity, onSelected: (a) => setState(() => _activity = a)),
          const SizedBox(height: 24),
          TextField(
            controller: _note,
            maxLength: 500,
            maxLines: 4,
            minLines: 2,
            decoration: const InputDecoration(
              labelText: 'Note (optional)',
              hintText: 'e.g. Co-op Stardew this evening, chill vibes only',
              border: OutlineInputBorder(),
            ),
          ),
          const SizedBox(height: 16),
          Text('Add-ons (optional)', style: theme.textTheme.titleSmall),
          Text(
            'Small, friendly gestures you’re comfortable with.',
            style: theme.textTheme.bodySmall?.copyWith(color: theme.colorScheme.onSurfaceVariant),
          ),
          const SizedBox(height: 8),
          if (catalog != null)
            ChipMultiSelect<Addon>(
              options: catalog,
              labelOf: (a) => a.name,
              selected: _addons,
              onChanged: (s) => setState(() => _addons = s),
            )
          else if (_catalogError != null)
            ErrorRetry(message: _catalogError!, onRetry: _loadCatalog)
          else
            const LinearProgressIndicator(),
          const SizedBox(height: 32),
          FilledButton(onPressed: _activity == null || _busy ? null : _submit, child: const Text('Post request')),
        ],
      ),
    );
  }
}
