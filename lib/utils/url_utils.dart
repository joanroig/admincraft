import 'package:flutter/foundation.dart';
import 'package:url_launcher/url_launcher.dart';

class UrlUtils {
  static const String documentationBaseUrl =
      'https://joanroig.github.io/admincraft/docs/';

  static Future<void> openUrl(String url) async {
    final Uri uri = Uri.parse(url);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, webOnlyWindowName: '_blank');
    } else {
      throw 'Could not launch $url';
    }
  }

  static Uri documentationUri({
    String page = '',
    bool? web,
    Uri? baseUri,
  }) {
    final runningOnWeb = web ?? kIsWeb;
    final root = runningOnWeb
        ? (baseUri ?? Uri.base).resolve('docs/')
        : Uri.parse(documentationBaseUrl);
    return root.resolve(page);
  }

  /// Opens documentation beside the web app when running in a browser. Native
  /// apps use the published site because they do not bundle the MkDocs output.
  static Future<void> openDocumentation([String page = '']) {
    final uri = documentationUri(page: page);
    return openUrl(uri.toString());
  }
}
