// Contract test against a real qmate-server: exercises the actual ApiClient
// parsers and the ChatConnection protocol end to end. Skipped unless
// QMATE_LIVE_TEST=1, since it needs the server running at API_BASE_URL
// (default http://localhost:8080):
//
//   QMATE_LIVE_TEST=1 flutter test test/live_server_contract_test.dart

import 'dart:async';
import 'dart:io';
import 'dart:math';

import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:qmate_client/core/api_client.dart';
import 'package:qmate_client/core/chat_connection.dart';
import 'package:qmate_client/core/models.dart';
import 'package:qmate_client/core/session.dart';

Future<(Session, ApiClient)> _signUp(String username) async {
  final session = Session(const FlutterSecureStorage());
  final api = ApiClient(session);
  final (token, user) = await api.register(
    username: username,
    displayName: username,
    password: 'password123',
    bio: '',
    roleTags: [RoleTag.walkBuddy],
    activityPrefs: [ActivityType.walk],
    adultConfirmed: true,
    acceptTerms: true,
  );
  await session.signIn(token, user);
  return (session, api);
}

void main() {
  final enabled = Platform.environment['QMATE_LIVE_TEST'] == '1';

  setUpAll(() {
    // flutter_test stubs out real HTTP by default.
    HttpOverrides.global = null;
    FlutterSecureStorage.setMockInitialValues({});
  });

  test(
    'register → create → discover → accept → two-sided chat → block',
    () async {
      final suffix = Random().nextInt(1 << 32).toRadixString(36);
      final (aSession, a) = await _signUp('ca_$suffix');
      final (bSession, b) = await _signUp('cb_$suffix');

      final addons = await a.addons();
      expect(addons.map((x) => x.name), contains('Hug goodbye'));
      await a.createRequest(activityType: ActivityType.movieNight, note: 'contract', addonIds: [addons.first.id]);

      final open = await b.discover(activity: ActivityType.movieNight);
      final req = open.firstWhere((r) => r.author.username == 'ca_$suffix');
      expect(req.addons, [addons.first.name]);

      final match = await b.acceptRequest(req.id);
      expect(match.otherUser!.username, 'ca_$suffix');
      expect((await a.myRequests()).single.status, RequestStatus.matched);

      final connA = await ChatConnection.open(matchId: match.id, token: aSession.token!);
      final connB = await ChatConnection.open(matchId: match.id, token: bSession.token!);
      final eventsA = StreamIterator(connA.events);
      final eventsB = StreamIterator(connB.events);
      for (final it in [eventsA, eventsB]) {
        expect(await it.moveNext(), isTrue);
        expect(it.current, isA<ChatReady>());
      }

      connA.send('hello from A');
      for (final it in [eventsA, eventsB]) {
        await it.moveNext();
        expect((it.current as ChatMessageReceived).message.body, 'hello from A');
      }

      final history = await b.messages(match.id);
      expect(history.map((m) => m.body), ['hello from A']);

      await a.block(bSession.user!.id);
      connB.send('are you there?');
      await eventsB.moveNext();
      expect((eventsB.current as ChatError).error, 'this conversation is closed');
      expect(await b.matches(), isEmpty);

      await connA.close();
      await connB.close();
    },
    skip: enabled ? false : 'set QMATE_LIVE_TEST=1 with qmate-server running',
  );

  test(
    'account deletion: wrong password keeps session; other side sees Deleted user',
    () async {
      final suffix = Random().nextInt(1 << 32).toRadixString(36);
      final (aSession, a) = await _signUp('xa_$suffix');
      final (_, b) = await _signUp('xb_$suffix');
      await a.createRequest(activityType: ActivityType.study, note: '', addonIds: []);
      final req = (await b.discover(activity: ActivityType.study)).firstWhere((r) => r.author.username == 'xa_$suffix');
      final match = await b.acceptRequest(req.id);

      await expectLater(a.deleteAccount('wrong-password'), throwsA(isA<ApiException>()));
      expect(aSession.isSignedIn, isTrue, reason: 'a wrong password must not sign the user out');

      await a.deleteAccount('password123');
      final remaining = (await b.matches()).firstWhere((m) => m.id == match.id);
      expect(remaining.otherUser, isNull);
      expect(remaining.otherName, 'Deleted user');
    },
    skip: enabled ? false : 'set QMATE_LIVE_TEST=1 with qmate-server running',
  );
}
