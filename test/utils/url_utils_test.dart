import 'package:admincraft/utils/url_utils.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('web documentation stays beside a localhost app', () {
    final uri = UrlUtils.documentationUri(
      page: 'guides/backup-transfer/',
      web: true,
      baseUri: Uri.parse('http://localhost:52656/'),
    );

    expect(
      uri.toString(),
      'http://localhost:52656/docs/guides/backup-transfer/',
    );
  });

  test('web documentation respects the deployed app base path', () {
    final uri = UrlUtils.documentationUri(
      web: true,
      baseUri: Uri.parse('https://joanroig.github.io/admincraft/'),
    );

    expect(
      uri.toString(),
      'https://joanroig.github.io/admincraft/docs/',
    );
  });

  test('native documentation uses the published site', () {
    final uri = UrlUtils.documentationUri(
      page: 'getting-started/first-server/',
      web: false,
    );

    expect(
      uri.toString(),
      'https://joanroig.github.io/admincraft/docs/getting-started/first-server/',
    );
  });
}
