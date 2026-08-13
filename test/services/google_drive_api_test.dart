import 'dart:convert';

import 'package:admincraft/services/google_drive_api.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';

void main() {
  test('creates an appDataFolder file with encrypted content', () async {
    late http.Request captured;
    final api = GoogleDriveApi(MockClient((request) async {
      captured = request;
      return http.Response(
        jsonEncode({
          'id': 'drive-file',
          'modifiedTime': '2026-08-11T12:00:00.000Z',
        }),
        200,
      );
    }));

    final result = await api.upload('{"encrypted":true}');

    expect(captured.method, 'POST');
    expect(captured.url.path, '/upload/drive/v3/files');
    expect(captured.url.queryParameters['uploadType'], 'multipart');
    expect(captured.body, contains('"parents":["appDataFolder"]'));
    expect(captured.body, contains('{"encrypted":true}'));
    expect(result.id, 'drive-file');
  });

  test('finds only the newest Admincraft app-data file', () async {
    late Uri captured;
    final api = GoogleDriveApi(MockClient((request) async {
      captured = request.url;
      return http.Response(
        jsonEncode({
          'files': [
            {
              'id': 'newest',
              'modifiedTime': '2026-08-11T12:00:00.000Z',
            }
          ],
        }),
        200,
      );
    }));

    final file = await api.findConfig();

    expect(captured.queryParameters['spaces'], 'appDataFolder');
    expect(captured.queryParameters['pageSize'], '1');
    expect(captured.queryParameters['orderBy'], 'modifiedTime desc');
    expect(captured.queryParameters['q'], contains('admincraft.json'));
    expect(file?.id, 'newest');
  });

  test('turns an expired grant into an actionable auth error', () async {
    final api = GoogleDriveApi(MockClient((_) async => http.Response('', 401)));

    expect(api.findConfig(), throwsA(isA<DriveAuthException>()));
  });
}
