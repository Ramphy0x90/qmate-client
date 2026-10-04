// Wire models for the qmate-server REST/WS API. The enums mirror Postgres
// enums on the server; adding a value there means adding it here too.

T _fromWire<T extends Enum>(List<T> values, String Function(T) wire, Object? raw) {
  for (final v in values) {
    if (wire(v) == raw) return v;
  }
  throw FormatException('unknown ${T.toString()} "$raw"');
}

enum ActivityType {
  gaming('gaming', 'Gaming'),
  hangout('hangout', 'Hangout'),
  walk('walk', 'Walk'),
  movieNight('movie_night', 'Movie night'),
  study('study', 'Study / cowork');

  const ActivityType(this.wire, this.label);
  final String wire;
  final String label;

  static ActivityType fromWire(Object? raw) => _fromWire(values, (v) => v.wire, raw);
}

enum RoleTag {
  gamingBuddy('gaming_buddy', 'Gaming buddy'),
  studyBuddy('study_buddy', 'Study buddy'),
  walkBuddy('walk_buddy', 'Walk buddy'),
  movieBuddy('movie_buddy', 'Movie buddy'),
  hangoutBuddy('hangout_buddy', 'Hangout buddy'),
  goodListener('good_listener', 'Good listener'),
  bigSiblingVibe('big_sibling_vibe', 'Big-sibling vibe'),
  littleSiblingVibe('little_sibling_vibe', 'Little-sibling vibe'),
  bestieVibe('bestie_vibe', 'Bestie vibe');

  const RoleTag(this.wire, this.label);
  final String wire;
  final String label;

  static RoleTag fromWire(Object? raw) => _fromWire(values, (v) => v.wire, raw);
}

enum RequestStatus {
  open('open', 'Open'),
  matched('matched', 'Matched'),
  cancelled('cancelled', 'Cancelled');

  const RequestStatus(this.wire, this.label);
  final String wire;
  final String label;

  static RequestStatus fromWire(Object? raw) => _fromWire(values, (v) => v.wire, raw);
}

List<T> _list<T>(Object? raw, T Function(Object?) parse) => (raw as List<dynamic>).map(parse).toList();

class Profile {
  const Profile({
    required this.id,
    required this.username,
    required this.displayName,
    required this.bio,
    required this.roleTags,
    required this.activityPrefs,
    required this.photoUrl,
  });

  final String id;
  final String username;
  final String displayName;
  final String bio;
  final List<RoleTag> roleTags;
  final List<ActivityType> activityPrefs;
  final String? photoUrl;

  factory Profile.fromJson(Map<String, dynamic> j) => Profile(
    id: j['id'] as String,
    username: j['username'] as String,
    displayName: j['display_name'] as String,
    bio: j['bio'] as String,
    roleTags: _list(j['role_tags'], RoleTag.fromWire),
    activityPrefs: _list(j['activity_prefs'], ActivityType.fromWire),
    photoUrl: j['photo_url'] as String?,
  );
}

class UserSummary {
  const UserSummary({
    required this.id,
    required this.username,
    required this.displayName,
    required this.photoUrl,
    required this.roleTags,
  });

  final String id;
  final String username;
  final String displayName;
  final String? photoUrl;
  final List<RoleTag> roleTags;

  factory UserSummary.fromJson(Map<String, dynamic> j) => UserSummary(
    id: j['id'] as String,
    username: j['username'] as String,
    displayName: j['display_name'] as String,
    photoUrl: j['photo_url'] as String?,
    roleTags: _list(j['role_tags'], RoleTag.fromWire),
  );
}

class Addon {
  const Addon({required this.id, required this.name});

  final int id;
  final String name;

  factory Addon.fromJson(Map<String, dynamic> j) => Addon(id: j['id'] as int, name: j['name'] as String);
}

class RequestView {
  const RequestView({
    required this.id,
    required this.author,
    required this.activityType,
    required this.note,
    required this.status,
    required this.addons,
    required this.createdAt,
  });

  final String id;
  final UserSummary author;
  final ActivityType activityType;
  final String note;
  final RequestStatus status;
  final List<String> addons;
  final DateTime createdAt;

  factory RequestView.fromJson(Map<String, dynamic> j) => RequestView(
    id: j['id'] as String,
    author: UserSummary.fromJson(j['author'] as Map<String, dynamic>),
    activityType: ActivityType.fromWire(j['activity_type']),
    note: j['note'] as String,
    status: RequestStatus.fromWire(j['status']),
    addons: _list(j['addons'], (e) => e as String),
    createdAt: DateTime.parse(j['created_at'] as String),
  );
}

class MatchView {
  const MatchView({
    required this.id,
    required this.requestId,
    required this.activityType,
    required this.otherUser,
    required this.createdAt,
  });

  final String id;

  /// Null once the request's author deleted their account.
  final String? requestId;
  final ActivityType activityType;

  /// Null when the other participant deleted their account.
  final UserSummary? otherUser;
  final DateTime createdAt;

  String get otherName => otherUser?.displayName ?? 'Deleted user';

  factory MatchView.fromJson(Map<String, dynamic> j) => MatchView(
    id: j['id'] as String,
    requestId: j['request_id'] as String?,
    activityType: ActivityType.fromWire(j['activity_type']),
    otherUser: j['other_user'] == null ? null : UserSummary.fromJson(j['other_user'] as Map<String, dynamic>),
    createdAt: DateTime.parse(j['created_at'] as String),
  );
}

class ChatMessage {
  const ChatMessage({
    required this.id,
    required this.matchId,
    required this.senderId,
    required this.body,
    required this.sentAt,
  });

  final String id;
  final String matchId;

  /// Null when the sender has since deleted their account.
  final String? senderId;
  final String body;
  final DateTime sentAt;

  factory ChatMessage.fromJson(Map<String, dynamic> j) => ChatMessage(
    id: j['id'] as String,
    matchId: j['match_id'] as String,
    senderId: j['sender_id'] as String?,
    body: j['body'] as String,
    sentAt: DateTime.parse(j['sent_at'] as String),
  );
}
