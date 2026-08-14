/// When this build was produced.
///
/// The package version alone does not identify a build: several builds share a
/// version during development, and a released version says nothing about when
/// its binary was made. The release workflow passes the time in:
///
///   flutter build ... --dart-define=ADMINCRAFT_BUILD_TIME=2026-08-14T10:30:00Z
///
/// Local builds leave it empty, which is treated as "unknown" rather than
/// shown as a wrong value.
class BuildInfo {
  static const String _raw = String.fromEnvironment('ADMINCRAFT_BUILD_TIME');

  static bool get isKnown => stamp != null;

  static String _two(int value) => value.toString().padLeft(2, '0');

  /// Compact stamp for display, `20260814-1030Z`, matching the form used
  /// elsewhere so two builds can be compared at a glance.
  static String? get stamp {
    final parsed = _parsed;
    if (parsed == null) return null;

    return '${parsed.year}${_two(parsed.month)}${_two(parsed.day)}'
        '-${_two(parsed.hour)}${_two(parsed.minute)}Z';
  }

  /// Full timestamp for a tooltip, where there is room to be readable.
  static String? get description {
    final parsed = _parsed;
    if (parsed == null) return null;

    return 'Built ${parsed.year}-${_two(parsed.month)}-${_two(parsed.day)} '
        '${_two(parsed.hour)}:${_two(parsed.minute)} UTC';
  }

  static DateTime? get _parsed {
    if (_raw.isEmpty) return null;
    return DateTime.tryParse(_raw)?.toUtc();
  }
}
