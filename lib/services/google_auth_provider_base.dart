import 'package:flutter/widgets.dart';
import 'package:http/http.dart' as http;

const googleDriveAppDataScope = 'https://www.googleapis.com/auth/drive.appdata';

abstract class GoogleAuthProvider {
  bool get configured;
  bool get signedIn;
  String? get email;
  Stream<bool> get authenticationChanges;

  Future<void> initialize({bool restoreMobileSession = true});
  Future<bool> restoreSession();
  Future<bool> signIn();
  Widget? buildSignInButton();
  Future<http.Client?> authenticatedClient({required bool interactive});
  Future<void> signOut();
  void dispose();
}

class BearerClient extends http.BaseClient {
  final String accessToken;
  final http.Client _inner;

  BearerClient(this.accessToken, [http.Client? inner])
    : _inner = inner ?? http.Client();

  @override
  Future<http.StreamedResponse> send(http.BaseRequest request) {
    request.headers['Authorization'] = 'Bearer $accessToken';
    return _inner.send(request);
  }

  @override
  void close() => _inner.close();
}

class NonClosingClient extends http.BaseClient {
  final http.Client inner;

  NonClosingClient(this.inner);

  @override
  Future<http.StreamedResponse> send(http.BaseRequest request) =>
      inner.send(request);
}
