import 'dart:async';
import 'dart:io';

import 'package:flutter/widgets.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:google_sign_in/google_sign_in.dart' as google;
import 'package:googleapis_auth/auth_io.dart' as google_auth;
import 'package:http/http.dart' as http;
import 'package:url_launcher/url_launcher.dart';

import 'google_auth_provider_base.dart';

const _webClientId = String.fromEnvironment('ADMINCRAFT_GOOGLE_WEB_CLIENT_ID');
const _desktopClientId =
    String.fromEnvironment('ADMINCRAFT_GOOGLE_DESKTOP_CLIENT_ID');
const _desktopClientSecret =
    String.fromEnvironment('ADMINCRAFT_GOOGLE_DESKTOP_CLIENT_SECRET');
const _refreshTokenKey = 'admincraft.google.refresh-token';

GoogleAuthProvider createGoogleAuthProvider() => _IoGoogleAuthProvider();

class _IoGoogleAuthProvider implements GoogleAuthProvider {
  final _changes = StreamController<bool>.broadcast();
  final _secureStorage = const FlutterSecureStorage();
  final _googleSignIn = google.GoogleSignIn.instance;

  StreamSubscription<google.GoogleSignInAuthenticationEvent>? _subscription;
  google.GoogleSignInAccount? _mobileAccount;
  google_auth.AutoRefreshingAuthClient? _desktopClient;
  bool _signedIn = false;
  bool _initialized = false;

  bool get _usesMobileSignIn => Platform.isAndroid;

  google_auth.ClientId get _desktopCredentials => google_auth.ClientId(
        _desktopClientId,
        _desktopClientSecret.isEmpty ? null : _desktopClientSecret,
      );

  @override
  bool get configured => _usesMobileSignIn
      ? _webClientId.isNotEmpty
      : Platform.isWindows && _desktopClientId.isNotEmpty;

  @override
  bool get signedIn => _signedIn;

  @override
  String? get email => _mobileAccount?.email;

  @override
  Stream<bool> get authenticationChanges => _changes.stream;

  void _setSignedIn(bool value) {
    if (_signedIn == value) return;
    _signedIn = value;
    _changes.add(value);
  }

  @override
  Future<void> initialize() async {
    if (_initialized || !configured) return;
    _initialized = true;
    try {
      if (_usesMobileSignIn) {
        _subscription = _googleSignIn.authenticationEvents.listen(
          (event) {
            switch (event) {
              case google.GoogleSignInAuthenticationEventSignIn():
                _mobileAccount = event.user;
                _setSignedIn(true);
              case google.GoogleSignInAuthenticationEventSignOut():
                _mobileAccount = null;
                _setSignedIn(false);
            }
          },
          onError: (_) {
            _mobileAccount = null;
            _setSignedIn(false);
          },
        );
        await _googleSignIn.initialize(serverClientId: _webClientId);
        final attempt = _googleSignIn.attemptLightweightAuthentication();
        if (attempt != null) {
          _mobileAccount = await attempt;
          _setSignedIn(_mobileAccount != null);
        }
        return;
      }

      final refreshToken = await _secureStorage.read(key: _refreshTokenKey);
      if (refreshToken == null || refreshToken.isEmpty) return;
      try {
        _desktopClient = await google_auth.clientViaRefreshToken(
          _desktopCredentials,
          refreshToken,
          const [googleDriveAppDataScope],
        );
        _setSignedIn(true);
      } catch (_) {
        await _secureStorage.delete(key: _refreshTokenKey);
        _setSignedIn(false);
      }
    } catch (_) {
      _initialized = false;
      await _subscription?.cancel();
      _subscription = null;
      rethrow;
    }
  }

  @override
  Future<bool> signIn() async {
    await initialize();
    if (!configured) return false;

    if (_usesMobileSignIn) {
      _mobileAccount = await _googleSignIn.authenticate(
        scopeHint: const [googleDriveAppDataScope],
      );
      await _mobileAccount!.authorizationClient.authorizeScopes(
        const [googleDriveAppDataScope],
      );
      _setSignedIn(true);
      return true;
    }

    final baseClient = http.Client();
    try {
      final credentials =
          await google_auth.obtainAccessCredentialsViaUserConsent(
        _desktopCredentials,
        const [googleDriveAppDataScope],
        baseClient,
        (url) => unawaited(
          launchUrl(Uri.parse(url), mode: LaunchMode.externalApplication),
        ),
        customPostAuthPage: '''
<!doctype html><html><body style="font-family: sans-serif; text-align: center; padding: 3rem">
<h2>Admincraft is connected</h2><p>You can close this tab and return to the app.</p>
</body></html>
''',
      );
      final refreshToken = credentials.refreshToken;
      if (refreshToken == null || refreshToken.isEmpty) {
        baseClient.close();
        return false;
      }
      await _secureStorage.write(
        key: _refreshTokenKey,
        value: refreshToken,
      );
      _desktopClient = google_auth.autoRefreshingClient(
        _desktopCredentials,
        credentials,
        baseClient,
      );
      _setSignedIn(true);
      return true;
    } catch (_) {
      baseClient.close();
      rethrow;
    }
  }

  @override
  Widget? buildSignInButton() => null;

  @override
  Future<http.Client?> authenticatedClient({required bool interactive}) async {
    await initialize();
    if (!_signedIn) return null;

    if (_usesMobileSignIn) {
      final account = _mobileAccount;
      if (account == null) return null;
      final authorization = await account.authorizationClient
              .authorizationForScopes(const [googleDriveAppDataScope]) ??
          (interactive
              ? await account.authorizationClient
                  .authorizeScopes(const [googleDriveAppDataScope])
              : null);
      return authorization == null
          ? null
          : BearerClient(authorization.accessToken);
    }

    final desktopClient = _desktopClient;
    return desktopClient == null ? null : NonClosingClient(desktopClient);
  }

  @override
  Future<void> signOut() async {
    if (_usesMobileSignIn) {
      await _googleSignIn.disconnect();
      _mobileAccount = null;
    } else {
      final token = await _secureStorage.read(key: _refreshTokenKey);
      if (token != null && token.isNotEmpty) {
        try {
          await http.post(
            Uri.https('oauth2.googleapis.com', '/revoke', {'token': token}),
          );
        } catch (_) {
          // Local sign-out must still succeed if revocation is offline.
        }
      }
      await _secureStorage.delete(key: _refreshTokenKey);
      _desktopClient?.close();
      _desktopClient = null;
    }
    _setSignedIn(false);
  }

  @override
  void dispose() {
    _subscription?.cancel();
    _changes.close();
    _desktopClient?.close();
  }
}
