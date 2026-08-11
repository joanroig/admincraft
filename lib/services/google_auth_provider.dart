import 'google_auth_provider_base.dart';
import 'google_auth_provider_stub.dart'
    if (dart.library.io) 'google_auth_provider_io.dart'
    if (dart.library.js_interop) 'google_auth_provider_web.dart' as platform;

export 'google_auth_provider_base.dart';

GoogleAuthProvider createGoogleAuthProvider() =>
    platform.createGoogleAuthProvider();
