import 'package:flutter_test/flutter_test.dart';
import 'package:qmate_client/core/models.dart';

void main() {
  test('RequestView parses the server shape', () {
    final r = RequestView.fromJson({
      'id': 'r1',
      'author': {
        'id': 'u1',
        'username': 'ana',
        'display_name': 'Ana',
        'photo_url': null,
        'role_tags': ['walk_buddy', 'big_sibling_vibe'],
      },
      'activity_type': 'movie_night',
      'note': 'hi',
      'status': 'open',
      'addons': ['Hug goodbye'],
      'created_at': '2026-10-04T12:00:00Z',
    });
    expect(r.activityType, ActivityType.movieNight);
    expect(r.author.roleTags, [RoleTag.walkBuddy, RoleTag.bigSiblingVibe]);
    expect(r.status, RequestStatus.open);
    expect(r.createdAt.isUtc, isTrue);
  });

  test('unknown enum values fail loudly instead of silently mapping', () {
    expect(() => ActivityType.fromWire('date'), throwsFormatException);
  });
}
