import 'dart:async';

import 'package:admincraft/models/model.dart';
import 'package:admincraft/services/config_transfer.dart';
import 'package:admincraft/services/google_auth_provider.dart';
import 'package:admincraft/services/google_drive_api.dart';
import 'package:admincraft/services/secure_value_store.dart';
import 'package:flutter/widgets.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

typedef DriveApiBuilder = GoogleDriveApi Function(http.Client client);

class GoogleDriveSyncController with ChangeNotifier {
  static const _enabledKey = 'googleDriveSyncEnabled';
  static const _lastSyncKey = 'googleDriveLastSync';
  static const _passphraseKey = 'admincraft.google-drive.passphrase';

  final SharedPreferences _preferences;
  final GoogleAuthProvider _auth;
  final SecureValueStore _secureValues;
  final DriveApiBuilder _driveApiBuilder;

  StreamSubscription<bool>? _authSubscription;
  Future<void>? _initialization;
  Timer? _syncTimer;
  Model? _model;
  Future<void> Function()? _onRemoteApplied;
  bool _busy = false;
  String? _error;

  GoogleDriveSyncController(
    this._preferences, {
    GoogleAuthProvider? auth,
    SecureValueStore? secureValues,
    DriveApiBuilder? driveApiBuilder,
  })  : _auth = auth ?? createGoogleAuthProvider(),
        _secureValues = secureValues ?? const PlatformSecureValueStore(),
        _driveApiBuilder = driveApiBuilder ?? GoogleDriveApi.new;

  bool get configured => _auth.configured;
  bool get signedIn => _auth.signedIn;
  String? get email => _auth.email;
  bool get busy => _busy;
  String? get error => _error;
  bool get automaticSyncEnabled => _preferences.getBool(_enabledKey) ?? false;

  DateTime? get lastSyncAt {
    final value = _preferences.getInt(_lastSyncKey);
    return value == null
        ? null
        : DateTime.fromMillisecondsSinceEpoch(value, isUtc: true);
  }

  Widget? buildSignInButton() => _auth.buildSignInButton();

  Future<void> initialize(
    Model model, {
    Future<void> Function()? onRemoteApplied,
  }) {
    _model = model;
    _onRemoteApplied ??= onRemoteApplied;
    return _initialization ??= _initialize();
  }

  Future<void> _initialize() async {
    _authSubscription = _auth.authenticationChanges.listen((signedIn) {
      notifyListeners();
      if (signedIn && automaticSyncEnabled && _model != null) {
        scheduleSync(_model!);
      }
    });
    await _auth.initialize();
    notifyListeners();
    if (signedIn && automaticSyncEnabled && _model != null) {
      scheduleSync(_model!);
    }
  }

  Future<bool> signIn() async {
    _error = null;
    notifyListeners();
    try {
      final result = await _auth.signIn();
      notifyListeners();
      return result;
    } catch (error) {
      _error = 'Google sign-in failed: $error';
      notifyListeners();
      return false;
    }
  }

  Future<void> disconnect() async {
    _syncTimer?.cancel();
    await _auth.signOut();
    await _secureValues.delete(_passphraseKey);
    await _preferences.setBool(_enabledKey, false);
    await _preferences.remove(_lastSyncKey);
    _error = null;
    notifyListeners();
  }

  Future<void> enableWithUpload(Model model, String passphrase) async {
    await _run(() async {
      final api = await _api(interactive: true);
      try {
        final existing = await api.findConfig();
        await _upload(api, model, passphrase, existing: existing);
        await _enable(passphrase);
      } finally {
        api.close();
      }
    });
  }

  Future<void> enableWithDownload(Model model, String passphrase) async {
    await _run(() async {
      final api = await _api(interactive: true);
      try {
        final remote = await api.findConfig();
        if (remote == null) {
          throw const DriveSyncException(
            'No Admincraft configuration exists in this Google Drive yet.',
          );
        }
        await _download(api, model, passphrase, remote);
        await _enable(passphrase);
      } finally {
        api.close();
      }
    });
  }

  Future<void> uploadNow(Model model) async {
    await _run(() async {
      final passphrase = await _requiredPassphrase();
      final api = await _api(interactive: true);
      try {
        await _upload(
          api,
          model,
          passphrase,
          existing: await api.findConfig(),
        );
        await _recordSync();
      } finally {
        api.close();
      }
    });
  }

  Future<void> downloadNow(Model model) async {
    await _run(() async {
      final passphrase = await _requiredPassphrase();
      final api = await _api(interactive: true);
      try {
        final remote = await api.findConfig();
        if (remote == null) {
          throw const DriveSyncException(
            'No Admincraft configuration exists in this Google Drive yet.',
          );
        }
        await _download(api, model, passphrase, remote);
        await _recordSync();
      } finally {
        api.close();
      }
    });
  }

  Future<void> syncNow(Model model, {bool interactive = true}) async {
    if (_busy || !automaticSyncEnabled || !signedIn) return;
    await _run(() async {
      final passphrase = await _requiredPassphrase();
      final api = await _api(interactive: interactive);
      try {
        final remote = await api.findConfig();
        final localUpdated = model.serversUpdatedAt;
        final lastSync = lastSyncAt;

        if (remote == null) {
          await _upload(api, model, passphrase);
          await _recordSync();
          return;
        }

        final remoteChanged =
            lastSync == null || remote.modifiedAt.isAfter(lastSync);
        final localChanged = localUpdated != null &&
            (lastSync == null || localUpdated.isAfter(lastSync));

        if (remoteChanged && localChanged) {
          if (remote.modifiedAt.isAfter(localUpdated)) {
            await _download(api, model, passphrase, remote);
          } else {
            await _upload(api, model, passphrase, existing: remote);
          }
        } else if (remoteChanged) {
          await _download(api, model, passphrase, remote);
        } else if (localChanged) {
          await _upload(api, model, passphrase, existing: remote);
        }
        await _recordSync();
      } finally {
        api.close();
      }
    }, rethrowError: interactive);
  }

  void scheduleSync(Model model) {
    if (!automaticSyncEnabled || !signedIn) return;
    _syncTimer?.cancel();
    _syncTimer = Timer(
      const Duration(seconds: 1),
      () => unawaited(syncNow(model, interactive: false)),
    );
  }

  Future<GoogleDriveApi> _api({required bool interactive}) async {
    final client = await _auth.authenticatedClient(interactive: interactive);
    if (client == null) {
      throw const DriveAuthException();
    }
    return _driveApiBuilder(client);
  }

  Future<void> _upload(
    GoogleDriveApi api,
    Model model,
    String passphrase, {
    DriveConfigFile? existing,
  }) async {
    final blob = await ConfigTransfer.export(model.servers, passphrase);
    await api.upload(blob, existing: existing);
  }

  Future<void> _download(
    GoogleDriveApi api,
    Model model,
    String passphrase,
    DriveConfigFile remote,
  ) async {
    final blob = await api.download(remote.id);
    final servers = await ConfigTransfer.import(blob, passphrase);
    if (servers.isEmpty) {
      throw const DriveSyncException(
        'The Google Drive configuration contains no servers.',
      );
    }
    await model.replaceServers(servers);
    await _onRemoteApplied?.call();
  }

  Future<void> _enable(String passphrase) async {
    await _secureValues.write(_passphraseKey, passphrase);
    await _preferences.setBool(_enabledKey, true);
    await _recordSync();
  }

  Future<String> _requiredPassphrase() async {
    final passphrase = await _secureValues.read(_passphraseKey);
    if (passphrase == null || passphrase.isEmpty) {
      throw const DriveSyncException(
        'The sync passphrase is missing on this device. Set up sync again.',
      );
    }
    return passphrase;
  }

  Future<void> _recordSync() async {
    await _preferences.setInt(
      _lastSyncKey,
      DateTime.now().toUtc().millisecondsSinceEpoch,
    );
  }

  Future<void> _run(
    Future<void> Function() action, {
    bool rethrowError = true,
  }) async {
    _busy = true;
    _error = null;
    notifyListeners();
    try {
      await action();
    } on ConfigTransferException catch (error) {
      _error = error.message;
      if (rethrowError) rethrow;
    } on DriveSyncException catch (error) {
      _error = error.message;
      if (rethrowError) rethrow;
    } catch (error) {
      _error = 'Google Drive sync failed: $error';
      if (rethrowError) rethrow;
    } finally {
      _busy = false;
      notifyListeners();
    }
  }

  @override
  void dispose() {
    _syncTimer?.cancel();
    _authSubscription?.cancel();
    _auth.dispose();
    super.dispose();
  }
}
