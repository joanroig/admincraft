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

  /// Opens the published documentation, optionally at a page relative to the
  /// documentation root. Native apps and the hosted web app share these URLs.
  static Future<void> openDocumentation([String page = '']) {
    final uri = Uri.parse(documentationBaseUrl).resolve(page);
    return openUrl(uri.toString());
  }
}
