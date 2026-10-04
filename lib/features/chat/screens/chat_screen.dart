import 'dart:async';

import 'package:go_router/go_router.dart';
import 'package:material_ui/material_ui.dart';

import '../../../core/api_client.dart';
import '../../../core/chat_connection.dart';
import '../../../core/models.dart';
import '../../../core/routes.dart';
import '../../../core/session.dart';
import '../../../shared/widgets/initials_avatar.dart';
import '../../../shared/widgets/status_views.dart';
import '../../safety/safety_flows.dart';
import '../widgets/chat_composer.dart';
import '../widgets/connection_banner.dart';
import '../widgets/message_bubble.dart';

enum _Link { connecting, live, disconnected, ended }

/// Private chat for one match. History comes over REST; live messages (ours
/// included, as the server's ack) come over the match's WebSocket.
class ChatScreen extends StatefulWidget {
  const ChatScreen({super.key, required this.api, required this.session, required this.matchId, this.initialMatch});

  final ApiClient api;
  final Session session;
  final String matchId;

  /// Passed when navigating from a list; null on a cold deep link.
  final MatchView? initialMatch;

  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  static const _pageSize = 50;

  MatchView? _match;
  String? _fatalError;
  final Map<String, ChatMessage> _byId = {};
  List<ChatMessage> _messages = [];
  bool _historyLoaded = false; // a first-page load has finished, ok or not
  bool _gotFirstPage = false; // ...and at least one succeeded
  bool _hasOlder = false;
  bool _loadingOlder = false;
  // A failed older-page load stops scroll from retrying every frame; the next
  // successful reconnect clears it.
  bool _olderFailed = false;
  bool _opening = false;

  ChatConnection? _conn;
  StreamSubscription<ChatEvent>? _sub;
  _Link _link = _Link.connecting;
  String? _endedReason;

  @override
  void initState() {
    super.initState();
    _match = widget.initialMatch;
    _start();
  }

  @override
  void dispose() {
    _sub?.cancel();
    _conn?.close();
    super.dispose();
  }

  Future<void> _start() async {
    if (_match == null) {
      try {
        final matches = await widget.api.matches();
        final found = matches.where((m) => m.id == widget.matchId).firstOrNull;
        if (!mounted) return;
        if (found == null) {
          setState(() => _fatalError = "This conversation isn't available.");
          return;
        }
        setState(() => _match = found);
      } on ApiException catch (e) {
        if (mounted) setState(() => _fatalError = e.message);
        return;
      }
    }
    _connect();
  }

  Future<void> _connect() async {
    final token = widget.session.token;
    // _opening is set before the first await so a double-tapped Reconnect
    // can't open two sockets and leak one.
    if (token == null || _opening) return;
    _opening = true;
    setState(() => _link = _Link.connecting);
    final oldSub = _sub, oldConn = _conn;
    _sub = null;
    _conn = null;
    try {
      await oldSub?.cancel();
      await oldConn?.close();
      final conn = await ChatConnection.open(matchId: widget.matchId, token: token);
      if (!mounted) {
        conn.close();
        return;
      }
      _conn = conn;
      _sub = conn.events.listen(_onEvent, onDone: _onClosed, onError: (_) => _onClosed());
    } catch (_) {
      if (mounted) setState(() => _link = _Link.disconnected);
    } finally {
      _opening = false;
    }
  }

  void _onEvent(ChatEvent event) {
    switch (event) {
      case ChatReady():
        setState(() => _link = _Link.live);
        // Loaded after subscribing, so nothing sent in between is missed;
        // overlap with live messages is deduped by id.
        _loadLatest();
      case ChatMessageReceived(:final message):
        _merge([message]);
      case ChatError(:final error):
        switch (error) {
          case 'this conversation is closed' || 'not found':
            setState(() {
              _link = _Link.ended;
              _endedReason = _match?.otherUser == null
                  ? 'This person deleted their account.'
                  : 'This conversation has ended.';
            });
          case 'unauthorized':
            widget.session.signOut();
          case 'resync':
            break; // the socket closes next; _onClosed offers reconnect
          default:
            ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(error)));
        }
    }
  }

  void _onClosed() {
    if (!mounted || _link == _Link.ended) return;
    setState(() => _link = _Link.disconnected);
  }

  Future<void> _loadLatest() async {
    try {
      final latest = await widget.api.messages(widget.matchId);
      if (!mounted) return;
      if (!_gotFirstPage) _hasOlder = latest.length == _pageSize;
      _gotFirstPage = true;
      _historyLoaded = true;
      _olderFailed = false;
      _merge(latest);
    } on ApiException catch (e) {
      if (!mounted) return;
      setState(() => _historyLoaded = true);
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.message)));
    }
  }

  Future<void> _loadOlder() async {
    if (_loadingOlder || _olderFailed || !_hasOlder || _messages.isEmpty) return;
    _loadingOlder = true;
    try {
      final older = await widget.api.messages(widget.matchId, before: _messages.first.sentAt);
      if (!mounted) return;
      _hasOlder = older.length == _pageSize;
      _merge(older);
    } on ApiException catch (e) {
      if (!mounted) return;
      _olderFailed = true;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Couldn't load older messages: ${e.message}")));
    } finally {
      _loadingOlder = false;
    }
  }

  void _merge(List<ChatMessage> incoming) {
    setState(() {
      for (final m in incoming) {
        _byId[m.id] = m;
      }
      _messages = _byId.values.toList()..sort((a, b) => a.sentAt.compareTo(b.sentAt));
    });
  }

  Future<void> _block() async {
    final other = _match?.otherUser;
    if (other == null) return;
    final blocked = await confirmAndBlock(context, widget.api, userId: other.id, displayName: other.displayName);
    if (blocked && mounted) context.pop();
  }

  Future<void> _report() async {
    final other = _match?.otherUser;
    if (other == null) return;
    final blocked = await reportUser(context, widget.api, userId: other.id, displayName: other.displayName);
    if (blocked && mounted) context.pop();
  }

  @override
  Widget build(BuildContext context) {
    final match = _match;
    if (_fatalError != null) {
      return Scaffold(
        appBar: AppBar(),
        body: ErrorRetry(
          message: _fatalError!,
          onRetry: () {
            setState(() => _fatalError = null);
            _start();
          },
        ),
      );
    }
    if (match == null) {
      return Scaffold(
        appBar: AppBar(),
        body: const Center(child: CircularProgressIndicator()),
      );
    }
    final other = match.otherUser;
    final myId = widget.session.user?.id;

    return Scaffold(
      appBar: AppBar(
        titleSpacing: 0,
        title: InkWell(
          onTap: other == null ? null : () => context.push(Routes.userFor(other.id)),
          child: Row(
            children: [
              other == null
                  ? const CircleAvatar(radius: 16, child: Icon(Icons.person_off_outlined, size: 18))
                  : InitialsAvatar(name: other.displayName, photoUrl: other.photoUrl, radius: 16),
              const SizedBox(width: 10),
              Flexible(child: Text(match.otherName, overflow: TextOverflow.ellipsis)),
            ],
          ),
        ),
        actions: [
          if (other != null)
            PopupMenuButton<VoidCallback>(
              onSelected: (action) => action(),
              itemBuilder: (_) => [
                PopupMenuItem(value: () => context.push(Routes.userFor(other.id)), child: const Text('View profile')),
                PopupMenuItem(value: _report, child: const Text('Report')),
                PopupMenuItem(value: _block, child: const Text('Block')),
              ],
            ),
        ],
      ),
      body: Column(
        children: [
          Expanded(
            child: !_historyLoaded && _link != _Link.disconnected
                ? const Center(child: CircularProgressIndicator())
                : _messages.isEmpty && !_gotFirstPage
                // We couldn't fetch an existing conversation; don't present
                // it as a brand-new chat.
                ? ErrorRetry(message: "Couldn't load messages.", onRetry: _link == _Link.live ? _loadLatest : _connect)
                : _messages.isEmpty
                ? Center(
                    child: Padding(
                      padding: const EdgeInsets.all(32),
                      child: Text(
                        'You matched for ${match.activityType.label.toLowerCase()}. Say hi and plan somewhere public to meet!',
                        textAlign: TextAlign.center,
                      ),
                    ),
                  )
                : NotificationListener<ScrollNotification>(
                    onNotification: (n) {
                      if (n.metrics.extentAfter < 300) _loadOlder();
                      return false;
                    },
                    child: ListView.builder(
                      reverse: true,
                      padding: const EdgeInsets.symmetric(vertical: 8),
                      itemCount: _messages.length,
                      itemBuilder: (context, i) {
                        final message = _messages[_messages.length - 1 - i];
                        return MessageBubble(
                          key: ValueKey(message.id),
                          message: message,
                          isMine: message.senderId == myId,
                        );
                      },
                    ),
                  ),
          ),
          switch (_link) {
            _Link.live => const SizedBox.shrink(),
            _Link.connecting => const ConnectionBanner(message: 'Connecting…'),
            _Link.disconnected => ConnectionBanner(message: 'Disconnected.', onReconnect: _connect),
            _Link.ended => ConnectionBanner(message: _endedReason ?? 'This conversation has ended.'),
          },
          ChatComposer(enabled: _link == _Link.live, onSend: (body) => _conn?.send(body)),
        ],
      ),
    );
  }
}
