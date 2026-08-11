/// Writing an exported config to disk.
///
/// Native platforms use a save dialog while the browser starts a download.
/// Reading is not here: file_picker returns bytes on every platform, so
/// importing works the same everywhere.
///
/// The web implementation is the default and `dart:io` the override, so
/// targets without it resolve correctly.
library;

export 'config_file_web.dart' if (dart.library.io) 'config_file_io.dart';
