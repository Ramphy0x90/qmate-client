import 'package:go_router/go_router.dart';
import 'package:material_ui/material_ui.dart';

import '../../../core/api_client.dart';
import '../../../core/models.dart';
import '../../../core/routes.dart';
import '../../../shared/widgets/activity_chips.dart';
import '../../../shared/widgets/status_views.dart';
import '../widgets/request_card.dart';

/// Browse open requests (a list, not a swipe feed) and accept or decline them.
class DiscoverScreen extends StatefulWidget {
  const DiscoverScreen({super.key, required this.api});

  final ApiClient api;

  @override
  State<DiscoverScreen> createState() => _DiscoverScreenState();
}

class _DiscoverScreenState extends State<DiscoverScreen> {
  // Matches the server's page size; a shorter page means we've hit the end.
  static const _pageSize = 50;

  List<RequestView> _items = [];
  ActivityType? _filter;
  bool _loading = true;
  bool _loadingMore = false;
  bool _hasMore = false;
  // Set when a page load fails; stops scroll from retrying every frame until
  // the user taps Retry or refreshes.
  bool _loadMoreFailed = false;
  String? _error;
  String? _busyId;
  // Bumped on every refresh/filter change; responses from an older
  // generation are dropped so they can't overwrite the current list.
  int _generation = 0;

  @override
  void initState() {
    super.initState();
    _refresh();
  }

  Future<void> _refresh() async {
    final generation = ++_generation;
    setState(() {
      _error = null;
      _loadingMore = false;
      _loadMoreFailed = false;
      if (_items.isEmpty) _loading = true;
    });
    try {
      final items = await widget.api.discover(activity: _filter);
      if (!mounted || generation != _generation) return;
      setState(() {
        _items = items;
        _hasMore = items.length == _pageSize;
        _loading = false;
      });
    } on ApiException catch (e) {
      if (!mounted || generation != _generation) return;
      setState(() {
        _error = e.message;
        _loading = false;
      });
      // With a list on screen the error view isn't shown, so say it here.
      if (_items.isNotEmpty) _showSnack("Couldn't refresh: ${e.message}");
    }
  }

  Future<void> _loadMore() async {
    if (_loadingMore || _loadMoreFailed || !_hasMore || _items.isEmpty) return;
    final generation = _generation;
    setState(() => _loadingMore = true);
    try {
      final more = await widget.api.discover(before: _items.last.createdAt, activity: _filter);
      if (!mounted || generation != _generation) return;
      setState(() {
        _items = [..._items, ...more];
        _hasMore = more.length == _pageSize;
        _loadingMore = false;
      });
    } on ApiException {
      if (!mounted || generation != _generation) return;
      setState(() {
        _loadingMore = false;
        _loadMoreFailed = true;
      });
    }
  }

  void _retryLoadMore() {
    setState(() => _loadMoreFailed = false);
    _loadMore();
  }

  void _setFilter(ActivityType? filter) {
    setState(() {
      _filter = filter;
      _items = [];
    });
    _refresh();
  }

  Future<void> _accept(RequestView request) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('${request.activityType.label} with ${request.author.displayName}?'),
        content: const Text(
          "This opens a private chat with them. Meet somewhere public, and you can block or report at any time.",
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancel')),
          FilledButton(onPressed: () => Navigator.pop(context, true), child: const Text('Accept')),
        ],
      ),
    );
    if (confirmed != true || !mounted) return;

    setState(() => _busyId = request.id);
    try {
      final match = await widget.api.acceptRequest(request.id);
      if (!mounted) return;
      setState(() => _items = _items.where((r) => r.id != request.id).toList());
      context.push(Routes.chatFor(match.id), extra: match);
    } on ApiException catch (e) {
      if (!mounted) return;
      // 409: someone else got there first. Drop it from the list either way.
      if (e.statusCode == 409 || e.statusCode == 404) {
        setState(() => _items = _items.where((r) => r.id != request.id).toList());
      }
      _showSnack(e.message);
    } finally {
      if (mounted) setState(() => _busyId = null);
    }
  }

  Future<void> _decline(RequestView request) async {
    final previous = _items;
    setState(() => _items = _items.where((r) => r.id != request.id).toList());
    try {
      await widget.api.declineRequest(request.id);
    } on ApiException catch (e) {
      if (!mounted) return;
      setState(() => _items = previous);
      _showSnack(e.message);
    }
  }

  void _showSnack(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message)));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Discover'),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(52),
          child: Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: ActivityChips(selected: _filter, onSelected: _setFilter, allLabel: 'All', scrollable: true),
          ),
        ),
      ),
      body: _buildBody(),
    );
  }

  Widget _buildBody() {
    if (_loading) return const Center(child: CircularProgressIndicator());
    if (_error != null && _items.isEmpty) return ErrorRetry(message: _error!, onRetry: _refresh);
    return RefreshIndicator(
      onRefresh: _refresh,
      child: _items.isEmpty
          ? const EmptyListMessage(message: 'No open requests right now.\nPost your own from the Requests tab!')
          : NotificationListener<ScrollNotification>(
              onNotification: (n) {
                if (n.metrics.extentAfter < 400) _loadMore();
                return false;
              },
              child: ListView.builder(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.symmetric(vertical: 8),
                itemCount: _items.length + (_loadingMore || _loadMoreFailed ? 1 : 0),
                itemBuilder: (context, i) {
                  if (i == _items.length) {
                    return Padding(
                      padding: const EdgeInsets.all(16),
                      child: Center(
                        child: _loadMoreFailed
                            ? TextButton(onPressed: _retryLoadMore, child: const Text("Couldn't load more · Retry"))
                            : const CircularProgressIndicator(),
                      ),
                    );
                  }
                  final request = _items[i];
                  return RequestCard(
                    key: ValueKey(request.id),
                    request: request,
                    busy: _busyId == request.id,
                    onAccept: () => _accept(request),
                    onDecline: () => _decline(request),
                    onAuthorTap: () => context.push(Routes.userFor(request.author.id)),
                  );
                },
              ),
            ),
    );
  }
}
