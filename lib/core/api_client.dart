import 'package:dio/dio.dart';

import 'config.dart';
import 'models.dart';
import 'session.dart';

class ApiException implements Exception {
  const ApiException(this.message, {this.statusCode});

  final String message;
  final int? statusCode;

  @override
  String toString() => message;
}

/// Thin typed wrapper over the REST API. Every method throws [ApiException]
/// with a user-presentable message on failure.
class ApiClient {
  ApiClient(this._session)
    : _dio = Dio(
        BaseOptions(
          baseUrl: apiBaseUrl,
          connectTimeout: const Duration(seconds: 10),
          receiveTimeout: const Duration(seconds: 15),
        ),
      ) {
    _dio.interceptors.add(
      InterceptorsWrapper(
        onRequest: (options, handler) {
          final token = _session.token;
          if (token != null) options.headers['Authorization'] = 'Bearer $token';
          handler.next(options);
        },
        onError: (error, handler) {
          // Expired or revoked token: drop the session so the router sends the
          // user to login. Login's own 401 (wrong password) has no session yet.
          if (error.response?.statusCode == 401 &&
              _session.isSignedIn &&
              error.requestOptions.extra[_noSignOutOn401] != true) {
            _session.signOut();
          }
          handler.next(error);
        },
      ),
    );
  }

  final Session _session;
  final Dio _dio;

  static const _noSignOutOn401 = 'noSignOutOn401';

  Future<T> _call<T>(Future<T> Function() request) async {
    try {
      return await request();
    } on DioException catch (e) {
      final data = e.response?.data;
      final serverMessage = data is Map<String, dynamic> ? data['error'] as String? : null;
      throw ApiException(serverMessage ?? _fallbackMessage(e), statusCode: e.response?.statusCode);
    } on FormatException catch (e) {
      throw ApiException('Unexpected response from server (${e.message})');
    } on TypeError {
      throw const ApiException('Unexpected response from server');
    }
  }

  String _fallbackMessage(DioException e) => switch (e.type) {
    DioExceptionType.connectionTimeout ||
    DioExceptionType.connectionError => "Can't reach the server. Check your connection.",
    DioExceptionType.receiveTimeout => 'The server took too long to respond.',
    _ => 'Something went wrong (${e.response?.statusCode ?? 'network'}).',
  };

  List<T> _list<T>(Object? data, T Function(Map<String, dynamic>) parse) =>
      (data as List<dynamic>).map((e) => parse(e as Map<String, dynamic>)).toList();

  // ---- auth ----

  Future<(String, Profile)> login(String username, String password) => _call(() async {
    final r = await _dio.post<Map<String, dynamic>>('/auth/login', data: {'username': username, 'password': password});
    return (r.data!['token'] as String, Profile.fromJson(r.data!['user'] as Map<String, dynamic>));
  });

  Future<(String, Profile)> register({
    required String username,
    required String displayName,
    required String password,
    required String bio,
    required List<RoleTag> roleTags,
    required List<ActivityType> activityPrefs,
    required bool adultConfirmed,
    required bool acceptTerms,
  }) => _call(() async {
    final r = await _dio.post<Map<String, dynamic>>(
      '/auth/register',
      data: {
        'username': username,
        'display_name': displayName,
        'password': password,
        'bio': bio,
        'role_tags': roleTags.map((t) => t.wire).toList(),
        'activity_prefs': activityPrefs.map((a) => a.wire).toList(),
        'adult_confirmed': adultConfirmed,
        'accept_terms': acceptTerms,
      },
    );
    return (r.data!['token'] as String, Profile.fromJson(r.data!['user'] as Map<String, dynamic>));
  });

  // ---- profiles ----

  Future<Profile> me() => _call(() async {
    final r = await _dio.get<Map<String, dynamic>>('/me');
    return Profile.fromJson(r.data!);
  });

  Future<Profile> user(String id) => _call(() async {
    final r = await _dio.get<Map<String, dynamic>>('/users/$id');
    return Profile.fromJson(r.data!);
  });

  // ---- requests ----

  Future<List<Addon>> addons() => _call(() async {
    final r = await _dio.get<List<dynamic>>('/addons');
    return _list(r.data, Addon.fromJson);
  });

  Future<List<RequestView>> discover({DateTime? before, ActivityType? activity}) => _call(() async {
    final r = await _dio.get<List<dynamic>>(
      '/requests',
      queryParameters: {
        if (before != null) 'before': before.toUtc().toIso8601String(),
        if (activity != null) 'activity': activity.wire,
      },
    );
    return _list(r.data, RequestView.fromJson);
  });

  Future<List<RequestView>> myRequests({DateTime? before}) => _call(() async {
    final r = await _dio.get<List<dynamic>>(
      '/requests/mine',
      queryParameters: {if (before != null) 'before': before.toUtc().toIso8601String()},
    );
    return _list(r.data, RequestView.fromJson);
  });

  Future<void> createRequest({required ActivityType activityType, required String note, required List<int> addonIds}) =>
      _call(
        () => _dio.post<void>(
          '/requests',
          data: {'activity_type': activityType.wire, 'note': note, 'addon_ids': addonIds},
        ),
      );

  Future<MatchView> acceptRequest(String id) => _call(() async {
    final r = await _dio.post<Map<String, dynamic>>('/requests/$id/accept');
    return MatchView.fromJson(r.data!);
  });

  Future<void> declineRequest(String id) => _call(() => _dio.post<void>('/requests/$id/decline'));

  Future<void> cancelRequest(String id) => _call(() => _dio.post<void>('/requests/$id/cancel'));

  // ---- matches & chat history ----

  Future<List<MatchView>> matches() => _call(() async {
    final r = await _dio.get<List<dynamic>>('/matches');
    return _list(r.data, MatchView.fromJson);
  });

  Future<List<ChatMessage>> messages(String matchId, {DateTime? before}) => _call(() async {
    final r = await _dio.get<List<dynamic>>(
      '/matches/$matchId/messages',
      queryParameters: {if (before != null) 'before': before.toUtc().toIso8601String()},
    );
    return _list(r.data, ChatMessage.fromJson);
  });

  // ---- safety ----

  Future<void> block(String userId) => _call(() => _dio.post<void>('/blocks', data: {'user_id': userId}));

  Future<void> report(String userId, String reason) =>
      _call(() => _dio.post<void>('/reports', data: {'user_id': userId, 'reason': reason}));

  // ---- account ----

  /// Permanently deletes the signed-in account. A wrong password is a 401,
  /// which must not trigger the interceptor's sign-out, hence the check here.
  Future<void> deleteAccount(String password) => _call(
    () => _dio.delete<void>(
      '/me',
      data: {'password': password},
      options: Options(extra: {_noSignOutOn401: true}),
    ),
  );
}
