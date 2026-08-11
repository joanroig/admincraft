import 'dart:js_interop';

import 'package:web/web.dart' as web;

/// Downloads [contents] through a temporary in-memory browser URL.
Future<String?> saveConfigFile(String suggestedName, String contents) async {
  final parts = <web.BlobPart>[contents.toJS].toJS;
  final blob = web.Blob(
    parts,
    web.BlobPropertyBag(type: 'application/json;charset=utf-8'),
  );
  final url = web.URL.createObjectURL(blob);

  try {
    final anchor = web.HTMLAnchorElement()
      ..href = url
      ..download = suggestedName;
    web.document.body?.appendChild(anchor);
    anchor.click();
    anchor.remove();

    // Let the browser consume the URL before releasing its backing blob.
    await Future<void>.delayed(Duration.zero);
    return suggestedName;
  } finally {
    web.URL.revokeObjectURL(url);
  }
}
