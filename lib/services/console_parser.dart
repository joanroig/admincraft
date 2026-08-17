import 'package:admincraft/models/minecraft_edition.dart';
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
  static final RegExp _bedrockDaytime = RegExp(r'Daytime is (\d+)');
  static final RegExp _javaDaytime = RegExp(r'The time is (\d+)');
  static final RegExp _gamerule = RegExp(
    r'^\s*([A-Za-z]+)\s*=\s*(true|false|\d+)\s*$',
  );
  static final RegExp _javaGamerule = RegExp(
    r'^Gamerule ([A-Za-z]+) is currently set to: (true|false|\d+)$',
  );
  static final RegExp _bedrockPlayerCount = RegExp(
    r'There are (\d+)/(\d+) players online',
  );
  static final RegExp _javaPlayerCount = RegExp(
    r'There are (\d+) of a max of (\d+) players online(?::\s*(.*))?',
  );
  static final RegExp _bedrockConnected = RegExp(
    r'Player connected:\s*([^,]+)',
  );
  static final RegExp _bedrockDisconnected = RegExp(
    r'Player disconnected:\s*([^,]+)',
  );
  static final RegExp _javaConnected = RegExp(
    r':\s*([^:\r\n]+?) joined the game\s*$',
  );
  static final RegExp _javaDisconnected = RegExp(
    r':\s*([^:\r\n]+?) left the game\s*$',
  );
  static final RegExp _difficulty = RegExp(
    r'(?:the\s+)?difficulty(?:\s+is|\s+has been set to|\s+set to)?\s*:?\s*'
    r'(peaceful|easy|normal|hard)',
    caseSensitive: false,
  );
  static final RegExp _bedrockDifficulty = RegExp(
    r'set game difficulty to\s+(peaceful|easy|normal|hard)',
    caseSensitive: false,
  );

  /// Strips the leading `[2026-08-09 19:31:04:922 INFO]` stamp so the patterns
  /// above only have to match the message itself.
  static String stripPrefix(String line) {
    final end = line.indexOf('] ');
    if (line.startsWith('[') && end > 0) return line.substring(end + 2);
    return line;
  }

  static bool isGameruleReply(
    String line, {
    MinecraftEdition edition = MinecraftEdition.bedrock,
  }) {
    final normalized = stripPrefix(line).trim();
    return (edition == MinecraftEdition.java ? _javaGamerule : _gamerule)
        .hasMatch(normalized);
  }

  /// Applies everything [chunk] says about the world to [state].
  static WorldState apply(
    WorldState state,
    String chunk, {
    MinecraftEdition edition = MinecraftEdition.bedrock,
  }) {
    var result = state;

    for (final raw in chunk.split('\n')) {
      final line = stripPrefix(raw).trim();
      if (line.isEmpty) continue;

      final timePattern = edition == MinecraftEdition.java
          ? _javaDaytime
          : _bedrockDaytime;
      final time = timePattern.firstMatch(line);
      if (time != null) {
        result = result.copyWith(daytime: int.tryParse(time.group(1)!));
        continue;
      }

      final players = _playerCountPattern(edition).firstMatch(line);
      if (players != null) {
        result = result.copyWith(
          playersOnline: int.tryParse(players.group(1)!),
          playerLimit: int.tryParse(players.group(2)!),
        );
        continue;
      }

      final difficulty =
          _difficulty.firstMatch(line) ?? _bedrockDifficulty.firstMatch(line);
      if (difficulty != null) {
        result = result.copyWith(
          lastDifficulty: difficulty.group(1)!.toLowerCase(),
        );
        continue;
      }

      final rule =
          (edition == MinecraftEdition.java ? _javaGamerule : _gamerule)
              .firstMatch(line);
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
  static int? playerCountHeader(
    String line, {
    MinecraftEdition edition = MinecraftEdition.bedrock,
  }) {
    final match = _playerCountPattern(edition).firstMatch(stripPrefix(line));
    return match == null ? null : int.tryParse(match.group(1)!);
  }

  /// Java includes names on the same line as the player count. Bedrock sends
  /// them on the following line, so this returns an empty list there.
  static List<String> namesFromPlayerCountHeader(
    String line, {
    MinecraftEdition edition = MinecraftEdition.bedrock,
  }) {
    if (edition != MinecraftEdition.java) return const [];
    final match = _javaPlayerCount.firstMatch(stripPrefix(line));
    final names = match?.group(3)?.trim() ?? '';
    return names.isEmpty ? const [] : namesFrom(names);
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
  static List<(String, bool)> playerChanges(
    String chunk, {
    MinecraftEdition edition = MinecraftEdition.bedrock,
  }) {
    final changes = <(String, bool)>[];

    for (final raw in chunk.split('\n')) {
      final line = stripPrefix(raw);

      final joined =
          (edition == MinecraftEdition.java
                  ? _javaConnected
                  : _bedrockConnected)
              .firstMatch(line);
      if (joined != null) {
        changes.add((joined.group(1)!.trim(), true));
        continue;
      }

      final left =
          (edition == MinecraftEdition.java
                  ? _javaDisconnected
                  : _bedrockDisconnected)
              .firstMatch(line);
      if (left != null) {
        changes.add((left.group(1)!.trim(), false));
      }
    }

    return changes;
  }

  static RegExp _playerCountPattern(MinecraftEdition edition) =>
      edition == MinecraftEdition.java ? _javaPlayerCount : _bedrockPlayerCount;
}
