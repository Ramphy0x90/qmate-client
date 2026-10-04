import 'package:go_router/go_router.dart';
import 'package:material_ui/material_ui.dart';

import '../../../core/api_client.dart';
import '../../../core/models.dart';
import '../../../core/routes.dart';
import '../../../shared/widgets/status_views.dart';
import '../widgets/match_tile.dart';

class MatchesScreen extends StatefulWidget {
  const MatchesScreen({super.key, required this.api});

  final ApiClient api;

  @override
  State<MatchesScreen> createState() => _MatchesScreenState();
}

class _MatchesScreenState extends State<MatchesScreen> {
  List<MatchView> _items = [];
  bool _loading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _refresh();
  }

  Future<void> _refresh() async {
    if (!mounted) return;
    setState(() => _error = null);
    try {
      final items = await widget.api.matches();
      if (!mounted) return;
      setState(() {
        _items = items;
        _loading = false;
      });
    } on ApiException catch (e) {
      if (!mounted) return;
      setState(() {
        _error = e.message;
        _loading = false;
      });
      if (_items.isNotEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Couldn't refresh: ${e.message}")));
      }
    }
  }

  Future<void> _open(MatchView match) async {
    await context.push(Routes.chatFor(match.id), extra: match);
    // The chat may have ended in a block; reflect that.
    _refresh();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Matches')),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _error != null && _items.isEmpty
          ? ErrorRetry(message: _error!, onRetry: _refresh)
          : RefreshIndicator(
              onRefresh: _refresh,
              child: _items.isEmpty
                  ? const EmptyListMessage(message: 'No matches yet.\nAccept a request on Discover, or post your own.')
                  : ListView.builder(
                      physics: const AlwaysScrollableScrollPhysics(),
                      itemCount: _items.length,
                      itemBuilder: (context, i) =>
                          MatchTile(key: ValueKey(_items[i].id), match: _items[i], onTap: () => _open(_items[i])),
                    ),
            ),
    );
  }
}
