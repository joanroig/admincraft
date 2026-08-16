/// A host as typed, and what it actually means.
///
/// People paste what they have. That is usually a URL, because every guide to
/// Tailscale, Funnel or a reverse proxy hands them one, and the field wants
/// only the host part: pasting `https://host` produced `wss://https://host`,
/// which fails with nothing to explain it.
class HostInput {
  final String host;

  /// Set when the text carried one, so the port field can follow rather than
  /// leaving a pasted `host:8080` connecting to whatever was there before.
  final int? port;

  /// What was removed, for telling the reader their paste was understood.
  final bool hadScheme;
  final bool hadPath;

  const HostInput({
    required this.host,
    this.port,
    this.hadScheme = false,
    this.hadPath = false,
  });

  bool get wasCleaned => hadScheme || hadPath || port != null;

  static final _scheme = RegExp(r'^[a-zA-Z][a-zA-Z0-9+.\-]*://');

  /// Reduces anything URL-shaped to the host, and the port if one was given.
  ///
  /// Deliberately forgiving rather than strict: the alternative is a validation
  /// error telling someone their own server address is wrong.
  static HostInput parse(String raw) {
    var text = raw.trim();
    if (text.isEmpty) return const HostInput(host: '');

    final hadScheme = _scheme.hasMatch(text);
    if (hadScheme) text = text.replaceFirst(_scheme, '');

    // Credentials, if someone pasted them, belong to no field here.
    final at = text.lastIndexOf('@');
    if (at != -1) text = text.substring(at + 1);

    final cut = text.indexOf(RegExp(r'[/?#]'));
    final hadPath = cut != -1;
    if (hadPath) text = text.substring(0, cut);

    int? port;
    // IPv6 arrives bracketed, and its colons are not port separators.
    final bracketed = text.startsWith('[');
    final lastColon = text.lastIndexOf(':');
    final colonIsPort = bracketed
        ? lastColon > text.indexOf(']')
        : lastColon != -1 && text.indexOf(':') == lastColon;

    if (colonIsPort && lastColon != -1) {
      final candidate = int.tryParse(text.substring(lastColon + 1));
      if (candidate != null && candidate > 0 && candidate <= 65535) {
        port = candidate;
        text = text.substring(0, lastColon);
      }
    }

    return HostInput(
      host: text.trim(),
      port: port,
      hadScheme: hadScheme,
      hadPath: hadPath,
    );
  }
}
