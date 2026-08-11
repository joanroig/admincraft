import 'package:admincraft/models/world_state.dart';

/// Reads state out of Bedrock Dedicated Server console output.
///
/// The patterns come from the server's actual replies rather than from
/// documentation, since the console format is not specified anywhere:
///
///   [INFO] Daytime is 5231
///   [INFO] keepInventory = false
///   [INFO] There are 0/10 players online:
class ConsoleParser {
  static final RegExp _daytime = RegExp(r'Daytime is (\d+)');
  static final RegExp _gamerule = RegExp(r'^\s*([A-Za-z]+)\s*=\s*(true|false|\d+)\s*$');
  static final RegExp _playerCount = RegExp(r'There are (\d+)/(\d+) players online');
  static final RegExp _connected = RegExp(r'Player connected:\s*([^,]+)');
  static final RegExp _disconnected = RegExp(r'Player disconnected:\s*([^,]+)');

  /// Strips the leading `[2026-08-09 19:31:04:922 INFO]` stamp so the patterns
  /// above only have to match the message itself.
  static String stripPrefix(String line) {
    final end = line.indexOf('] ');
    if (line.startsWith('[') && end > 0) return line.substring(end + 2);
    return line;
  }

  /// Applies everything [chunk] says about the world to [state].
  static WorldState apply(WorldState state, String chunk) {
    var result = state;

    for (final raw in chunk.split('\n')) {
      final line = stripPrefix(raw).trim();
      if (line.isEmpty) continue;

      final time = _daytime.firstMatch(line);
      if (time != null) {
        result = result.copyWith(daytime: int.tryParse(time.group(1)!));
        continue;
      }

      final players = _playerCount.firstMatch(line);
      if (players != null) {
        result = result.copyWith(
          playersOnline: int.tryParse(players.group(1)!),
          playerLimit: int.tryParse(players.group(2)!),
        );
        continue;
      }

      final rule = _gamerule.firstMatch(line);
      if (rule != null) {
        result = result.copyWith(
          gamerules: {...result.gamerules, rule.group(1)!: rule.group(2)!},
        );
      }
    }

    return result;
  }

  /// The online count if [line] is the header of a `list` reply.
  ///
  /// The names follow on the next line, which is why this is exposed
  /// separately rather than handled inside [apply]: the caller has to keep
  /// track across lines, and the two can even arrive in different messages.
  static int? playerCountHeader(String line) {
    final match = _playerCount.firstMatch(stripPrefix(line));
    return match == null ? null : int.tryParse(match.group(1)!);
  }

  /// Names from the line following a `list` header, which are comma separated.
  static List<String> namesFrom(String line) {
    return stripPrefix(line)
        .split(',')
        .map((name) => name.trim())
        .where((name) => name.isNotEmpty)
        .toList();
  }

  /// Player names joining or leaving in [chunk], as (name, joined) pairs.
  static List<(String, bool)> playerChanges(String chunk) {
    final changes = <(String, bool)>[];

    for (final raw in chunk.split('\n')) {
      final line = stripPrefix(raw);

      final joined = _connected.firstMatch(line);
      if (joined != null) {
        changes.add((joined.group(1)!.trim(), true));
        continue;
      }

      final left = _disconnected.firstMatch(line);
      if (left != null) {
        changes.add((left.group(1)!.trim(), false));
      }
    }

    return changes;
  }
}
