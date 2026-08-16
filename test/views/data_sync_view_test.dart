import 'package:admincraft/controllers/google_drive_sync_controller.dart';
import 'package:admincraft/models/model.dart';
import 'package:admincraft/services/google_auth_provider_base.dart';
import 'package:admincraft/services/persistence_service.dart';
import 'package:admincraft/views/data_sync_view.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  testWidgets('forgotten Drive passphrase offers safe recovery choices', (
    tester,
  ) async {
    SharedPreferences.setMockInitialValues({});
    final preferences = await SharedPreferences.getInstance();
    final model = Model(PersistenceService(preferences));
    final drive = GoogleDriveSyncController(preferences, auth: _SignedInAuth());

    await tester.pumpWidget(
      MultiProvider(
        providers: [
          ChangeNotifierProvider.value(value: model),
          ChangeNotifierProvider.value(value: drive),
        ],
        child: MaterialApp(
          home: Scaffold(body: DataSyncView(onServersChanged: () async {})),
        ),
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.text('Forgot passphrase?'));
    await tester.pumpAndSettle();

    expect(find.text('Forgot the sync passphrase?'), findsOneWidget);
    expect(find.text('Disconnect Drive'), findsOneWidget);
    expect(find.text('Replace Drive copy'), findsOneWidget);
    expect(
      find.textContaining('If Drive is your only remaining copy'),
      findsOneWidget,
    );

    await tester.tap(find.text('Cancel'));
    await tester.pumpAndSettle();
    expect(find.text('Forgot the sync passphrase?'), findsNothing);
    expect(tester.takeException(), isNull);
  });
}

class _SignedInAuth implements GoogleAuthProvider {
  final http.Client _client = MockClient((_) async => http.Response('{}', 200));

  @override
  bool get configured => true;

  @override
  bool get signedIn => true;

  @override
  String? get email => 'test@example.com';

  @override
  Stream<bool> get authenticationChanges => const Stream.empty();

  @override
  Future<void> initialize({bool restoreMobileSession = true}) async {}

  @override
  Future<bool> restoreSession() async => true;

  @override
  Future<bool> signIn() async => true;

  @override
  Widget? buildSignInButton() => null;

  @override
  Future<http.Client?> authenticatedClient({required bool interactive}) async =>
      _client;

  @override
  Future<void> signOut() async {}

  @override
  void dispose() => _client.close();
}
