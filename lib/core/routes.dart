/// Every navigable path. Never hardcode a path string elsewhere; use these
/// constants (as GoRoute patterns) or the `...For` builders (to navigate).
class Routes {
  Routes._();

  static const login = '/login';
  static const register = '/register';

  static const discover = '/discover';
  static const myRequests = '/requests';
  static const createRequest = '/requests/new';
  static const matches = '/matches';
  static const profile = '/profile';

  static const chat = '/matches/:matchId';
  static const user = '/users/:userId';

  static String chatFor(String matchId) => '/matches/$matchId';
  static String userFor(String userId) => '/users/$userId';
}
