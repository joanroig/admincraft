import 'dart:convert';

import 'package:http/http.dart' as http;

class DriveSyncException implements Exception {
  final String message;
  const DriveSyncException(this.message);

  @override
  String toString() => message;
}

class DriveAuthException extends DriveSyncException {
  const DriveAuthException()
      : super('Google Drive authorization expired. Sign in again to continue.');
}

class DriveConfigFile {
  final String id;
  final DateTime modifiedAt;

  const DriveConfigFile({required this.id, required this.modifiedAt});
}

class GoogleDriveApi {
  static const fileName = 'admincraft.json';

  final http.Client client;

  const GoogleDriveApi(this.client);

  void close() => client.close();

  Future<DriveConfigFile?> findConfig() async {
    final uri = Uri.https('www.googleapis.com', '/drive/v3/files', {
      'spaces': 'appDataFolder',
      'q': "name = '$fileName' and trashed = false",
      'orderBy': 'modifiedTime desc',
      'pageSize': '1',
      'fields': 'files(id,modifiedTime)',
    });
    final response = await client.get(uri);
    _check(response);
    final decoded = jsonDecode(response.body) as Map<String, dynamic>;
    final files = decoded['files'] as List<dynamic>? ?? const [];
    if (files.isEmpty) return null;
    final file = files.first as Map<String, dynamic>;
    return DriveConfigFile(
      id: file['id'] as String,
      modifiedAt: DateTime.parse(file['modifiedTime'] as String).toUtc(),
    );
  }

  Future<String> download(String fileId) async {
    final response = await client.get(
      Uri.https('www.googleapis.com', '/drive/v3/files/$fileId', {
        'alt': 'media',
      }),
    );
    _check(response);
    return response.body;
  }

  Future<DriveConfigFile> upload(
    String encryptedConfig, {
    DriveConfigFile? existing,
  }) async {
    final http.Response response;
    if (existing == null) {
      const boundary = 'admincraft-drive-upload';
      final metadata = jsonEncode({
        'name': fileName,
        'parents': ['appDataFolder'],
      });
      final body = '--$boundary\r\n'
          'Content-Type: application/json; charset=UTF-8\r\n\r\n'
          '$metadata\r\n'
          '--$boundary\r\n'
          'Content-Type: application/json\r\n\r\n'
          '$encryptedConfig\r\n'
          '--$boundary--\r\n';
      response = await client.post(
        Uri.https('www.googleapis.com', '/upload/drive/v3/files', {
          'uploadType': 'multipart',
          'fields': 'id,modifiedTime',
        }),
        headers: {
          'Content-Type': 'multipart/related; boundary=$boundary',
        },
        body: body,
      );
    } else {
      response = await client.patch(
        Uri.https(
          'www.googleapis.com',
          '/upload/drive/v3/files/${existing.id}',
          {'uploadType': 'media', 'fields': 'id,modifiedTime'},
        ),
        headers: const {'Content-Type': 'application/json'},
        body: encryptedConfig,
      );
    }
    _check(response);
    final decoded = jsonDecode(response.body) as Map<String, dynamic>;
    return DriveConfigFile(
      id: decoded['id'] as String,
      modifiedAt: DateTime.parse(decoded['modifiedTime'] as String).toUtc(),
    );
  }

  void _check(http.Response response) {
    if (response.statusCode == 401) {
      throw const DriveAuthException();
    }
    if (response.statusCode < 200 || response.statusCode >= 300) {
      String detail = '';
      try {
        final decoded = jsonDecode(response.body) as Map<String, dynamic>;
        final error = decoded['error'] as Map<String, dynamic>?;
        detail = error?['message'] as String? ?? '';
      } catch (_) {}
      throw DriveSyncException(
        detail.isEmpty
            ? 'Google Drive returned error ${response.statusCode}.'
            : 'Google Drive: $detail',
      );
    }
  }
}
