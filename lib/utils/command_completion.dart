import 'package:admincraft/data/bedrock_commands.dart';
import 'package:admincraft/data/bedrock_gamerules.dart';
import 'package:admincraft/data/bedrock_ids.dart';
import 'package:admincraft/models/bedrock_command.dart';

class Completion {
  /// The value to insert.
  final String value;

  /// Shown next to the value, e.g. what a command does.
  final String detail;

  /// What kind of value this is, so it can be given an icon. Null for command
  /// names, which are rendered with their syntax instead.
  final ArgType? type;

  const Completion(this.value, [this.detail = '', this.type]);
}

class CommandCompletion {
  /// Suggestions for [input], based on which argument is being typed.
  ///
  /// The first word completes to a command name; later words complete from the
  /// vocabulary that argument accepts. [onlinePlayers] comes from the server
  /// log rather than a fixed list, so player arguments complete to people who
  /// are actually connected.
  static List<Completion> suggest(String input, {Set<String> onlinePlayers = const {}}) {
    // A trailing space means the current word is empty: the user has finished
    // the previous argument and is starting the next one.
    final atNewWord = input.isEmpty || input.endsWith(' ');
    final words = input.trimLeft().split(RegExp(r'\s+')).where((w) => w.isNotEmpty).toList();

    if (words.isEmpty || (words.length == 1 && !atNewWord)) {
      return _commands(words.isEmpty ? '' : words.first);
    }

    final command = BedrockCommands.byName[words.first.toLowerCase()];
    if (command == null) return const [];

    // Index of the argument being typed, counting from after the command name.
    final argIndex = atNewWord ? words.length - 1 : words.length - 2;
    final prefix = atNewWord ? '' : words.last;

    final arg = command.argAt(argIndex);
    if (arg == null) return const [];

    return _forArg(arg, prefix, onlinePlayers);
  }

  /// The command whose syntax should be displayed for [input], if any.
  static BedrockCommand? commandFor(String input) {
    final words = input.trimLeft().split(RegExp(r'\s+')).where((w) => w.isNotEmpty).toList();
    if (words.isEmpty) return null;
    return BedrockCommands.byName[words.first.toLowerCase()];
  }

  /// Which argument index [input] is currently on, for highlighting the hint.
  static int activeArgIndex(String input) {
    final atNewWord = input.isEmpty || input.endsWith(' ');
    final words = input.trimLeft().split(RegExp(r'\s+')).where((w) => w.isNotEmpty).toList();
    if (words.length <= 1) return atNewWord && words.isNotEmpty ? 0 : -1;
    return atNewWord ? words.length - 1 : words.length - 2;
  }

  /// Replaces the word being typed with [value], leaving a trailing space so
  /// the next argument can be completed immediately.
  static String apply(String input, String value) {
    final atNewWord = input.isEmpty || input.endsWith(' ');
    if (atNewWord) return '$input$value ';

    final lastSpace = input.lastIndexOf(' ');
    if (lastSpace < 0) return '$value ';
    return '${input.substring(0, lastSpace + 1)}$value ';
  }

  static List<Completion> _commands(String prefix) {
    return _rank(
      BedrockCommands.all.map((c) => Completion(c.name, c.description)).toList(),
      prefix,
    );
  }

  static List<Completion> _forArg(CommandArg arg, String prefix, Set<String> onlinePlayers) {
    switch (arg.type) {
      case ArgType.literal:
        return _rank(arg.options.map((o) => Completion(o, '', ArgType.literal)).toList(), prefix);
      case ArgType.player:
        return _rank(
          onlinePlayers.map((player) => Completion(player, 'online', ArgType.player)).toList(),
          prefix,
        );
      case ArgType.item:
        return _rank(BedrockIds.items.map((i) => Completion(i, '', ArgType.item)).toList(), prefix);
      case ArgType.entity:
        return _rank(BedrockIds.entities.map((e) => Completion(e, '', ArgType.entity)).toList(), prefix);
      case ArgType.effect:
        return _rank(BedrockIds.effects.map((e) => Completion(e, '', ArgType.effect)).toList(), prefix);
      case ArgType.enchantment:
        return _rank(
            BedrockIds.enchantments.map((e) => Completion(e, '', ArgType.enchantment)).toList(), prefix);
      case ArgType.gamerule:
        return _rank(
            BedrockIds.gamerules
                .map((g) => Completion(g, BedrockGamerules.forName(g).label, ArgType.gamerule))
                .toList(),
            prefix);
      case ArgType.number:
      case ArgType.text:
      case ArgType.position:
        return const [];
    }
  }

  /// Prefix matches first, then matches anywhere, so typing "sword" still
  /// finds "diamond_sword" while "diamond" keeps the diamond items on top.
  static List<Completion> _rank(List<Completion> candidates, String prefix) {
    if (prefix.isEmpty) return candidates.take(_limit).toList();

    final needle = prefix.toLowerCase();
    final starts = <Completion>[];
    final contains = <Completion>[];

    for (final candidate in candidates) {
      final value = candidate.value.toLowerCase();
      if (value.startsWith(needle)) {
        starts.add(candidate);
      } else if (value.contains(needle)) {
        contains.add(candidate);
      }
    }

    return [...starts, ...contains].take(_limit).toList();
  }

  static const int _limit = 40;
}
