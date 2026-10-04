import 'dart:async';
import 'dart:convert';

import 'package:web_socket_channel/web_socket_channel.dart';

import 'config.dart';
import 'models.dart';

sealed class ChatEvent {
  const ChatEvent();
}

class ChatReady extends ChatEvent {
  const ChatReady();
}

class ChatMessageReceived extends ChatEvent {
  const ChatMessageReceived(this.message);
  final ChatMessage message;
}

class ChatError extends ChatEvent {
  const ChatError(this.error);
  final String error;
}

/// One live chat socket for a match. Protocol (see qmate-server/src/chat.rs):
/// first frame is `{"type":"auth","token":...}`, then `{"type":"send","body":...}`.
/// The server echoes our own messages back as the delivery ack.
class ChatConnection {
  ChatConnection._(this._channel) : events = _channel.stream.map(_decode).where((e) => e != null).cast<ChatEvent>();

  final WebSocketChannel _channel;

  /// Single-subscription; completes (onDone) when the socket closes, from
  /// either side. Unrecognised or malformed frames are dropped, not errors.
  final Stream<ChatEvent> events;

  static Future<ChatConnection> open({required String matchId, required String token}) async {
    final base = Uri.parse(apiBaseUrl);
    // Keep any path prefix (e.g. https://host/api), as dio does for REST.
    final prefix = base.path.endsWith('/') ? base.path.substring(0, base.path.length - 1) : base.path;
    final uri = base.replace(scheme: base.scheme == 'https' ? 'wss' : 'ws', path: '$prefix/matches/$matchId/ws');
    final channel = WebSocketChannel.connect(uri);
    await channel.ready;
    channel.sink.add(jsonEncode({'type': 'auth', 'token': token}));
    return ChatConnection._(channel);
  }

  static ChatEvent? _decode(dynamic raw) {
    if (raw is! String) return null;
    try {
      final frame = jsonDecode(raw) as Map<String, dynamic>;
      return switch (frame['type']) {
        'ready' => const ChatReady(),
        'message' => ChatMessageReceived(ChatMessage.fromJson(frame['message'] as Map<String, dynamic>)),
        'error' => ChatError(frame['error'] as String),
        _ => null,
      };
    } on Object {
      return null;
    }
  }

  void send(String body) => _channel.sink.add(jsonEncode({'type': 'send', 'body': body}));

  Future<void> close() async => _channel.sink.close();
}
