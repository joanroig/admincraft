import 'package:admincraft/services/console_parser.dart';

/// Applies the user's console presentation settings consistently everywhere
/// server output is shown.
class ConsoleOutputFormatter {
  /// Conservative, repetitive server messages that do not describe a player,
  /// command result, warning, or state change.
  ///
  /// Keep this list deliberately narrow: hiding an important line by default
  /// is worse than leaving a little noise visible.
  static const commonNoiseFragments = <String>[
    'running autocompaction',
    'autocompaction completed',
    'autocompaction complete',
    'autocompaction finished',
  ];

  static bool isCommonNoise(String line) {
    final message = ConsoleParser.stripPrefix(line).trim().toLowerCase();
    return commonNoiseFragments.any(message.contains);
  }

  static List<String> visibleLines(
    String output, {
    required bool hideCommonNoise,
    String containing = '',
  }) {
    final needle = containing.trim().toLowerCase();
    return output.split('\n').where((line) {
      if (line.trim().isEmpty) return false;
      if (hideCommonNoise && isCommonNoise(line)) return false;
      return needle.isEmpty || line.toLowerCase().contains(needle);
    }).toList();
  }

  static String formatLine(String line, String timestampMode) {
    if (timestampMode == 'hidden') return ConsoleParser.stripPrefix(line);
    if (timestampMode != 'short') return line;

    final match = RegExp(
      r'^\[\d{4}-\d{2}-\d{2}\s+(\d{2}:\d{2})(?::\d{2}[^\s]*)?\s+([^\]]+)\]\s*(.*)$',
    ).firstMatch(line);
    if (match == null) return line;
    return '[${match.group(1)} ${match.group(2)}] ${match.group(3)}';
  }
}
