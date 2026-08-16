import 'package:admincraft/models/minecraft_edition.dart';
import 'package:admincraft/services/console_parser.dart';

/// Matches replies to automatic status probes so they can update app state
/// without being stored as user-facing server logs.
class QuietCommandFilter {
  final List<_PendingQuietReply> _pending = [];

  void expect(String command, MinecraftEdition edition) {
    final reply = _PendingQuietReply.fromCommand(command, edition);
    if (reply != null) _pending.add(reply);
  }

  bool shouldHide(String line) {
    final now = DateTime.now();
    _pending.removeWhere((reply) => reply.expiresAt.isBefore(now));

    for (final reply in List<_PendingQuietReply>.from(_pending)) {
      if (!reply.consume(line)) continue;
      return true;
    }
    return false;
  }

  void clear() => _pending.clear();
}

enum _QuietReplyKind { daytime, players, gamerule }

class _PendingQuietReply {
  final _QuietReplyKind kind;
  final MinecraftEdition edition;
  final String? gamerule;
  DateTime expiresAt = DateTime.now().add(const Duration(seconds: 8));
  bool _awaitingPlayerNames = false;

  _PendingQuietReply(this.kind, this.edition, {this.gamerule});

  static _PendingQuietReply? fromCommand(
    String command,
    MinecraftEdition edition,
  ) {
    final normalized = command.trim().toLowerCase();
    if (normalized == 'time query daytime') {
      return _PendingQuietReply(_QuietReplyKind.daytime, edition);
    }
    if (normalized == 'list') {
      return _PendingQuietReply(_QuietReplyKind.players, edition);
    }
    final gamerule = RegExp(r'^gamerule\s+(\S+)$').firstMatch(normalized);
    if (gamerule != null) {
      return _PendingQuietReply(
        _QuietReplyKind.gamerule,
        edition,
        gamerule: gamerule.group(1),
      );
    }
    return null;
  }

  bool consume(String rawLine) {
    final line = ConsoleParser.stripPrefix(rawLine).trim();
    if (line.isEmpty) return false;

    return switch (kind) {
      _QuietReplyKind.daytime => _consumeDaytime(line),
      _QuietReplyKind.players => _consumePlayers(rawLine),
      _QuietReplyKind.gamerule => _consumeGamerule(line),
    };
  }

  bool _consumeDaytime(String line) {
    final matches = edition == MinecraftEdition.java
        ? RegExp(r'^The time is \d+$').hasMatch(line)
        : RegExp(r'^Daytime is \d+$').hasMatch(line);
    if (matches) _markComplete();
    return matches;
  }

  bool _consumePlayers(String rawLine) {
    if (_awaitingPlayerNames) {
      _awaitingPlayerNames = false;
      _markComplete();
      return true;
    }

    final count = ConsoleParser.playerCountHeader(rawLine, edition: edition);
    if (count == null) return false;
    _awaitingPlayerNames = edition == MinecraftEdition.bedrock && count > 0;
    if (!_awaitingPlayerNames) _markComplete();
    return true;
  }

  bool _consumeGamerule(String line) {
    final rule = RegExp.escape(gamerule!);
    final matches = edition == MinecraftEdition.java
        ? RegExp(
            '^Gamerule $rule is currently set to:',
            caseSensitive: false,
          ).hasMatch(line)
        : RegExp('^$rule\\s*=', caseSensitive: false).hasMatch(line);
    if (matches) _markComplete();
    return matches;
  }

  void _markComplete() {
    // Bedrock can return a command result directly and then repeat it through
    // the followed Docker log. Keep the matcher briefly after the first reply
    // so both copies stay quiet, without hiding a manual query later on.
    expiresAt = DateTime.now().add(const Duration(seconds: 2));
  }
}
