import 'dart:async';

import 'package:flutter/widgets.dart';
import 'package:google_sign_in/google_sign_in.dart' as google;
import 'package:google_sign_in_web/web_only.dart' as google_web;
import 'package:http/http.dart' as http;

import 'google_auth_provider_base.dart';

const _webClientId = String.fromEnvironment('ADMINCRAFT_GOOGLE_WEB_CLIENT_ID');

GoogleAuthProvider createGoogleAuthProvider() => _WebGoogleAuthProvider();

class _WebGoogleAuthProvider implements GoogleAuthProvider {
  final _changes = StreamController<bool>.broadcast();
  final _googleSignIn = google.GoogleSignIn.instance;

  StreamSubscription<google.GoogleSignInAuthenticationEvent>? _subscription;
  google.GoogleSignInAccount? _account;
  bool _initialized = false;

  @override
  bool get configured => _webClientId.isNotEmpty;

  @override
  bool get signedIn => _account != null;

  @override
  String? get email => _account?.email;

  @override
  Stream<bool> get authenticationChanges => _changes.stream;

  @override
  Future<void> initialize() async {
    if (_initialized || !configured) return;
    _initialized = true;
    try {
      _subscription = _googleSignIn.authenticationEvents.listen(
        (event) {
          switch (event) {
            case google.GoogleSignInAuthenticationEventSignIn():
              _account = event.user;
              _changes.add(true);
            case google.GoogleSignInAuthenticationEventSignOut():
              _account = null;
              _changes.add(false);
          }
        },
        onError: (_) {
          _account = null;
          _changes.add(false);
        },
      );
      await _googleSignIn.initialize(clientId: _webClientId);
      final attempt = _googleSignIn.attemptLightweightAuthentication();
      if (attempt != null) {
        _account = await attempt;
        _changes.add(_account != null);
      }
    } catch (_) {
      _initialized = false;
      await _subscription?.cancel();
      _subscription = null;
      rethrow;
    }
  }

  @override
  Future<bool> signIn() async => false;

  @override
  Widget? buildSignInButton() {
    if (!configured || !_initialized) return null;
    return google_web.renderButton(
      configuration: google_web.GSIButtonConfiguration(
        type: google_web.GSIButtonType.standard,
        text: google_web.GSIButtonText.signinWith,
        size: google_web.GSIButtonSize.large,
      ),
    );
  }

  @override
  Future<http.Client?> authenticatedClient({required bool interactive}) async {
    final account = _account;
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

  @override
  Future<void> signOut() async {
    await _googleSignIn.disconnect();
    _account = null;
    _changes.add(false);
  }

  @override
  void dispose() {
    _subscription?.cancel();
    _changes.close();
  }
}
