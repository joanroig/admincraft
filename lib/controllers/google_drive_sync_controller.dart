import 'dart:async';

import 'package:admincraft/models/model.dart';
import 'package:admincraft/services/config_transfer.dart';
import 'package:admincraft/services/google_auth_provider.dart';
import 'package:admincraft/services/google_drive_api.dart';
import 'package:admincraft/services/secure_value_store.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

typedef DriveApiBuilder = GoogleDriveApi Function(http.Client client);

class GoogleDriveSyncController with ChangeNotifier {
  static const _enabledKey = 'googleDriveSyncEnabled';
  static const _connectedKey = 'googleDriveConnected';
  static const _lastSyncKey = 'googleDriveLastSync';
  static const _passphraseKey = 'admincraft.google-drive.passphrase';

  final SharedPreferences _preferences;
  final GoogleAuthProvider _auth;
  final SecureValueStore _secureValues;
  final DriveApiBuilder _driveApiBuilder;
  final bool _isWeb;

  StreamSubscription<bool>? _authSubscription;
  Future<void>? _initialization;
  Timer? _syncTimer;
  Model? _model;
  int _observedServerRevision = 0;
  Future<void> Function()? _onRemoteApplied;
  bool _busy = false;
  bool _scheduledSyncRunning = false;
  String? _error;

  GoogleDriveSyncController(
    this._preferences, {
    GoogleAuthProvider? auth,
    SecureValueStore? secureValues,
    DriveApiBuilder? driveApiBuilder,
    bool? platformIsWeb,
  }) : _auth = auth ?? createGoogleAuthProvider(),
       _secureValues = secureValues ?? const PlatformSecureValueStore(),
       _driveApiBuilder = driveApiBuilder ?? GoogleDriveApi.new,
       _isWeb = platformIsWeb ?? kIsWeb;

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
    if (_model != model) {
      _model?.removeListener(_handleModelChanged);
      _model = model;
      _observedServerRevision = model.serverRevision;
      model.addListener(_handleModelChanged);
    }
    _onRemoteApplied ??= onRemoteApplied;
    return _initialization ??= _initialize();
  }

  void _handleModelChanged() {
    final model = _model;
    if (model == null) return;
    final revision = model.serverRevision;
    if (revision == _observedServerRevision) return;
    _observedServerRevision = revision;
    if (!_busy) scheduleSync(model);
  }

  /// Whether this device has connected Drive sync at some point.
  ///
  /// `automaticSyncEnabled` counts too: it is the flag earlier versions set,
  /// and a device that was syncing before this one existed should still have
  /// its provider prepared. Desktop refresh tokens can restore silently;
  /// Android deliberately waits for an explicit sign-in action.
  bool get _everConnected =>
      (_preferences.getBool(_connectedKey) ?? false) || automaticSyncEnabled;

  Future<void> _initialize() async {
    _authSubscription = _auth.authenticationChanges.listen((signedIn) {
      notifyListeners();
      if (signedIn &&
          automaticSyncEnabled &&
          _model != null &&
          !_scheduledSyncRunning) {
        scheduleSync(_model!);
      }
    });

    // Only prepare authentication after Drive has actually been used. An
    // enabled automatic sync must restore its Android session here so startup
    // can discover a newer remote copy. Credential Manager owns the brief
    // system sign-in surface used for that restoration; it is skipped when
    // automatic sync is not enabled.
    // The web flow must initialize Google Identity Services before its sign-in
    // button can be rendered. Unlike Android, doing that does not raise an
    // account chooser, so first-time web users can be prepared safely here.
    if (_everConnected || _isWeb) {
      await _auth.initialize(restoreMobileSession: automaticSyncEnabled);
    }

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
      // Remembered so later starts prepare the provider. Desktop may restore
      // through its refresh token; Android waits for another explicit action
      // rather than flashing Credential Manager over every launch.
      if (result) await _preferences.setBool(_connectedKey, true);
      notifyListeners();
      return result;
    } catch (error) {
      _error = _signInMessage(error);
      notifyListeners();
      return false;
    }
  }

  /// Turns a sign-in failure into something the reader can act on.
  ///
  /// The plugin's own text describes what the credential layer saw, not what
  /// is wrong. "Account reauth failed" in particular is what Android reports
  /// when it cannot match the running app to an OAuth client, which is a
  /// setup problem in the Google Cloud project rather than anything the user
  /// did, and is easy to hit after the app's signing key changes.
  static String _signInMessage(Object error) {
    final text = error.toString();

    if (text.contains('reauth failed') || text.contains('10:')) {
      return 'Google refused the sign-in because this build is not '
          'registered in its Google Cloud project. An Android OAuth client '
          'is needed for the package name and the signing certificate of this '
          'exact build. See the Google Drive sync guide in the docs.';
    }
    if (text.contains('access_denied') || text.contains('verification')) {
      return 'Google blocked the sign-in because this build\'s Google Cloud '
          'project is still in testing, so only accounts its owner has added '
          'as testers may use Drive sync. Build with your own client IDs to '
          'use your own project, or use Backup file instead.';
    }
    if (text.contains('canceled') || text.contains('cancelled')) {
      return 'Sign-in was cancelled.';
    }
    if (text.contains('network') || text.contains('SocketException')) {
      return 'Sign-in could not reach Google. Check the connection and try '
          'again.';
    }
    return 'Google sign-in failed: $error';
  }

  Future<void> disconnect() async {
    _syncTimer?.cancel();
    await _auth.signOut();
    await _secureValues.delete(_passphraseKey);
    await _preferences.setBool(_enabledKey, false);
    // Also stops the next start from trying to restore the session that was
    // just given up.
    await _preferences.remove(_connectedKey);
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
        await _upload(api, model, passphrase, existing: await api.findConfig());
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
        final localChanged =
            localUpdated != null &&
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
    if (!automaticSyncEnabled) return;
    _syncTimer?.cancel();
    _syncTimer = Timer(
      const Duration(seconds: 1),
      () => unawaited(_runScheduledSync(model)),
    );
  }

  Future<void> _runScheduledSync(Model model) async {
    if (_scheduledSyncRunning) return;
    _scheduledSyncRunning = true;
    try {
      if (!signedIn) {
        final bool restored;
        try {
          restored = await _auth.restoreSession();
        } catch (error) {
          _error = _signInMessage(error);
          notifyListeners();
          return;
        }
        notifyListeners();
        if (!restored) {
          _error = 'Sign in to Google Drive again to resume automatic sync.';
          notifyListeners();
          return;
        }
      }
      await syncNow(model, interactive: false);
    } finally {
      _scheduledSyncRunning = false;
    }
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
    _model?.removeListener(_handleModelChanged);
    _auth.dispose();
    super.dispose();
  }
}
