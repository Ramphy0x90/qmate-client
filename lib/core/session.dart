import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

import 'models.dart';

/// The signed-in user and their JWT. The token is persisted in secure storage;
/// the profile is re-fetched on launch. GoRouter listens to this to redirect
/// between the auth screens and the app.
class Session extends ChangeNotifier {
  Session(this._storage);

  static const _tokenKey = 'qmate_token';

  final FlutterSecureStorage _storage;
  String? _token;
  Profile? _user;

  String? get token => _token;
  Profile? get user => _user;
  bool get isSignedIn => _token != null && _user != null;

  // Secure storage can fail at the platform level (e.g. no keyring on Linux).
  // That should cost the user "remember me", never the ability to sign in.

  Future<String?> readStoredToken() async {
    try {
      return await _storage.read(key: _tokenKey);
    } on PlatformException catch (e) {
      debugPrint('secure storage read failed: $e');
      return null;
    }
  }

  /// Lets the API client authenticate the `/me` call that completes a restore,
  /// without telling listeners we're signed in yet. Pass null to back out.
  void adoptToken(String? token) => _token = token;

  Future<void> signIn(String token, Profile user) async {
    try {
      await _storage.write(key: _tokenKey, value: token);
    } on PlatformException catch (e) {
      debugPrint('secure storage write failed; session will not persist: $e');
    }
    _token = token;
    _user = user;
    notifyListeners();
  }

  Future<void> signOut() async {
    _token = null;
    _user = null;
    notifyListeners();
    try {
      await _storage.delete(key: _tokenKey);
    } on PlatformException catch (e) {
      debugPrint('secure storage delete failed: $e');
    }
  }
}
