import 'dart:async';

import 'package:flutter/widgets.dart';
import 'package:http/http.dart' as http;

import 'google_auth_provider_base.dart';

GoogleAuthProvider createGoogleAuthProvider() => _UnsupportedGoogleAuth();

class _UnsupportedGoogleAuth implements GoogleAuthProvider {
  @override
  bool get configured => false;

  @override
  bool get signedIn => false;

  @override
  String? get email => null;

  @override
  Stream<bool> get authenticationChanges => const Stream.empty();

  @override
  Future<void> initialize() async {}

  @override
  Future<bool> signIn() async => false;

  @override
  Widget? buildSignInButton() => null;

  @override
  Future<http.Client?> authenticatedClient({required bool interactive}) async =>
      null;

  @override
  Future<void> signOut() async {}

  @override
  void dispose() {}
}
