import 'package:admincraft/services/console_parser.dart';

/// Applies the user's console presentation settings consistently everywhere
/// server output is shown.
class ConsoleOutputFormatter {
  /// Stored before locally echoed commands so identical text returned by the
  /// server is not mistaken for something the user typed. A private-use
  /// character survives persistence but is removed before anything renders.
  static const String userCommandMarker = '\uE000';

  static String markUserCommand(String line) => '$userCommandMarker$line';

  static bool isUserCommand(String line) => line.startsWith(userCommandMarker);

  static String stripUserCommandMarker(String line) =>
      isUserCommand(line) ? line.substring(userCommandMarker.length) : line;

  /// Removes terminal decoration emitted by container supervisors and shell
  /// wrappers before text reaches Flutter. Minecraft's output is plain text,
  /// so rendering raw ANSI escape bytes only exposes fragments such as
  /// `[37mDEBUG[0m` and other control glyphs in the console.
  static String sanitize(String line) => line
      .replaceAll(RegExp(r'\x1B\[[0-?]*[ -/]*[@-~]'), '')
      .replaceAll(RegExp(r'\x1B\][^\x07]*(?:\x07|\x1B\\)'), '')
      .replaceAll(RegExp(r'[\x00-\x08\x0B\x0C\x0E-\x1A\x1C-\x1F\x7F]'), '');

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
    'connected to bedrock bridge (',
    'connected to java bridge (',
  ];

  static bool isCommonNoise(String line) {
    final message = ConsoleParser.stripPrefix(
      stripUserCommandMarker(sanitize(line)),
    ).trim().toLowerCase();
    return commonNoiseFragments.any(message.contains) ||
        ConsoleParser.isGameruleReply(message) ||
        RegExp(r'^daytime is \d+$').hasMatch(message) ||
        RegExp(r'^the time is \d+$').hasMatch(message) ||
        RegExp(
          r'^there are \d+(?:/| of a max of )\d+ players online:',
        ).hasMatch(message);
  }

  static List<String> visibleLines(
    String output, {
    required bool hideCommonNoise,
    String containing = '',
  }) {
    final needle = containing.trim().toLowerCase();
    return output.split('\n').map(sanitize).where((line) {
      if (line.trim().isEmpty) return false;
      if (hideCommonNoise && isCommonNoise(line)) return false;
      return needle.isEmpty || line.toLowerCase().contains(needle);
    }).toList();
  }

  static String formatLine(String line, String timestampMode) {
    line = stripUserCommandMarker(sanitize(line));
    if (timestampMode == 'hidden') return ConsoleParser.stripPrefix(line);
    if (timestampMode != 'short') return line;

    final match = RegExp(
      r'^\[\d{4}-\d{2}-\d{2}\s+(\d{2}:\d{2})(?::\d{2}[^\s]*)?\s+([^\]]+)\]\s*(.*)$',
    ).firstMatch(line);
    if (match == null) return line;
    return '[${match.group(1)} ${match.group(2)}] ${match.group(3)}';
  }
}
