import 'package:flutter/foundation.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:go_router/go_router.dart';
import 'package:material_ui/material_ui.dart';

import 'core/api_client.dart';
import 'core/config.dart';
import 'core/router.dart';
import 'core/session.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  // Passwords, tokens and chat must never go over cleartext in a release
  // build. Android/iOS would block it anyway; web and desktop would not.
  if (kReleaseMode && !apiBaseUrl.startsWith('https://')) {
    throw StateError('Release builds require an https API_BASE_URL (got $apiBaseUrl)');
  }
  final session = Session(const FlutterSecureStorage());
  final api = ApiClient(session);
  await _restoreSession(session, api);
  runApp(
    QmateApp(
      router: createRouter(session: session, api: api),
    ),
  );
}

/// Signs back in with a stored token. A 401 clears it; any other failure
/// (e.g. server unreachable) leaves it stored so the next launch can retry.
Future<void> _restoreSession(Session session, ApiClient api) async {
  final token = await session.readStoredToken();
  if (token == null) return;
  session.adoptToken(token);
  try {
    final user = await api.me();
    await session.signIn(token, user);
  } on ApiException catch (e) {
    if (e.statusCode == 401) {
      await session.signOut();
    } else {
      session.adoptToken(null); // still stored for next launch; show login now
    }
  }
}

class QmateApp extends StatelessWidget {
  const QmateApp({super.key, required this.router});

  final GoRouter router;

  @override
  Widget build(BuildContext context) {
    return MaterialApp.router(
      title: 'Qmate',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(colorSchemeSeed: const Color(0xFF3E8E7E)),
      darkTheme: ThemeData(colorSchemeSeed: const Color(0xFF3E8E7E), brightness: Brightness.dark),
      routerConfig: router,
    );
  }
}
