import 'package:go_router/go_router.dart';
import 'package:material_ui/material_ui.dart';

import '../../../core/api_client.dart';
import '../../../core/models.dart';
import '../../../core/routes.dart';
import '../../../shared/widgets/status_views.dart';
import '../widgets/my_request_tile.dart';

class MyRequestsScreen extends StatefulWidget {
  const MyRequestsScreen({super.key, required this.api});

  final ApiClient api;

  @override
  State<MyRequestsScreen> createState() => _MyRequestsScreenState();
}

class _MyRequestsScreenState extends State<MyRequestsScreen> {
  static const _pageSize = 50; // matches the server

  List<RequestView> _items = [];
  bool _loading = true;
  bool _hasMore = false;
  bool _loadingMore = false;
  String? _error;
  String? _busyId;

  @override
  void initState() {
    super.initState();
    _refresh();
  }

  Future<void> _refresh() async {
    if (!mounted) return;
    setState(() => _error = null);
    try {
      final items = await widget.api.myRequests();
      if (!mounted) return;
      setState(() {
        _items = items;
        _hasMore = items.length == _pageSize;
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

  /// Explicit button rather than scroll-triggered: lists here are short, and
  /// a failure can't turn into a retry loop.
  Future<void> _loadMore() async {
    setState(() => _loadingMore = true);
    try {
      final more = await widget.api.myRequests(before: _items.last.createdAt);
      if (!mounted) return;
      setState(() {
        _items = [..._items, ...more];
        _hasMore = more.length == _pageSize;
      });
    } on ApiException catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.message)));
    } finally {
      if (mounted) setState(() => _loadingMore = false);
    }
  }

  Future<void> _create() async {
    final created = await context.push<bool>(Routes.createRequest);
    if (created == true) _refresh();
  }

  Future<void> _cancel(RequestView request) async {
    setState(() => _busyId = request.id);
    try {
      await widget.api.cancelRequest(request.id);
      await _refresh();
    } on ApiException catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.message)));
      // 404 usually means it was matched meanwhile; show the current state.
      await _refresh();
    } finally {
      if (mounted) setState(() => _busyId = null);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('My requests')),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _create,
        icon: const Icon(Icons.add),
        label: const Text('New request'),
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _error != null && _items.isEmpty
          ? ErrorRetry(message: _error!, onRetry: _refresh)
          : RefreshIndicator(
              onRefresh: _refresh,
              child: _items.isEmpty
                  ? const EmptyListMessage(message: "You haven't posted anything yet.")
                  : ListView.separated(
                      physics: const AlwaysScrollableScrollPhysics(),
                      padding: const EdgeInsets.only(bottom: 88),
                      itemCount: _items.length + (_hasMore ? 1 : 0),
                      separatorBuilder: (_, _) => const Divider(height: 1),
                      itemBuilder: (context, i) => i == _items.length
                          ? Padding(
                              padding: const EdgeInsets.all(12),
                              child: Center(
                                child: _loadingMore
                                    ? const CircularProgressIndicator()
                                    : TextButton(onPressed: _loadMore, child: const Text('Load older requests')),
                              ),
                            )
                          : MyRequestTile(
                              key: ValueKey(_items[i].id),
                              request: _items[i],
                              busy: _busyId == _items[i].id,
                              onCancel: () => _cancel(_items[i]),
                            ),
                    ),
            ),
    );
  }
}
