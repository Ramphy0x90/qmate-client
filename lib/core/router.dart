import 'package:go_router/go_router.dart';
import 'package:material_ui/material_ui.dart';

import '../features/auth/screens/login_screen.dart';
import '../features/auth/screens/register_screen.dart';
import '../features/chat/screens/chat_screen.dart';
import '../features/discover/screens/discover_screen.dart';
import '../features/home/screens/home_shell.dart';
import '../features/matches/screens/matches_screen.dart';
import '../features/profile/screens/profile_screen.dart';
import '../features/profile/screens/user_profile_screen.dart';
import '../features/requests/screens/create_request_screen.dart';
import '../features/requests/screens/my_requests_screen.dart';
import 'api_client.dart';
import 'models.dart';
import 'routes.dart';
import 'session.dart';

/// Screens get their dependencies (api, session) through constructors from
/// here. There's no DI container or state-management package.
GoRouter createRouter({required Session session, required ApiClient api}) {
  return GoRouter(
    initialLocation: Routes.discover,
    refreshListenable: session,
    redirect: (context, state) {
      final atAuth = state.matchedLocation == Routes.login || state.matchedLocation == Routes.register;
      if (!session.isSignedIn) return atAuth ? null : Routes.login;
      if (atAuth) return Routes.discover;
      return null;
    },
    routes: [
      GoRoute(
        path: Routes.login,
        builder: (_, _) => LoginScreen(api: api, session: session),
      ),
      GoRoute(
        path: Routes.register,
        builder: (_, _) => RegisterScreen(api: api, session: session),
      ),
      StatefulShellRoute.indexedStack(
        builder: (_, _, shell) => HomeShell(shell: shell),
        branches: [
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: Routes.discover,
                builder: (_, _) => DiscoverScreen(api: api),
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: Routes.myRequests,
                builder: (_, _) => MyRequestsScreen(api: api),
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: Routes.matches,
                builder: (_, _) => MatchesScreen(api: api),
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: Routes.profile,
                builder: (_, _) => ProfileScreen(api: api, session: session),
              ),
            ],
          ),
        ],
      ),
      // Full-screen routes pushed over the tab shell.
      GoRoute(
        path: Routes.createRequest,
        builder: (_, _) => CreateRequestScreen(api: api),
      ),
      GoRoute(
        path: Routes.chat,
        builder: (_, state) => ChatScreen(
          api: api,
          session: session,
          matchId: state.pathParameters['matchId']!,
          initialMatch: state.extra is MatchView ? state.extra as MatchView : null,
        ),
      ),
      GoRoute(
        path: Routes.user,
        builder: (_, state) => UserProfileScreen(api: api, userId: state.pathParameters['userId']!),
      ),
    ],
    errorBuilder: (_, _) => const Scaffold(body: Center(child: Text('Page not found'))),
  );
}
