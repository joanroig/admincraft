import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:file_picker/file_picker.dart';

/// Asks where to save and writes [contents] there.
///
/// Returns the path written, or null if the user cancelled.
Future<String?> saveConfigFile(String suggestedName, String contents) async {
  final mobile = Platform.isAndroid || Platform.isIOS;
  final path = await FilePicker.platform.saveFile(
    dialogTitle: 'Export Admincraft servers',
    fileName: suggestedName,
    type: FileType.custom,
    allowedExtensions: const ['json'],
    // Android and iOS receive a document URI rather than a path the app can
    // open afterwards, so file_picker must write the bytes itself there.
    bytes: mobile ? Uint8List.fromList(utf8.encode(contents)) : null,
  );
  if (path == null) return null;

  if (!mobile) await File(path).writeAsString(contents);
  return path;
}
