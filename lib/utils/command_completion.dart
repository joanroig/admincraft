import 'package:admincraft/data/bedrock_gamerules.dart';
import 'package:admincraft/data/bedrock_ids.dart';
import 'package:admincraft/data/java_ids.dart';
import 'package:admincraft/data/minecraft_commands.dart';
import 'package:admincraft/models/bedrock_command.dart';
import 'package:admincraft/models/minecraft_edition.dart';

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
  static List<Completion> suggest(
    String input, {
    Set<String> onlinePlayers = const {},
    Map<String, int> usage = const {},
    MinecraftEdition edition = MinecraftEdition.bedrock,
    bool includeMinecraftCommands = true,
    bool includeBridgeManagement = false,
    Set<String>? bridgeCapabilities,
  }) {
    // A trailing space means the current word is empty: the user has finished
    // the previous argument and is starting the next one.
    final atNewWord = input.isEmpty || input.endsWith(' ');
    final words = input
        .trimLeft()
        .split(RegExp(r'\s+'))
        .where((w) => w.isNotEmpty)
        .toList();

    if (words.isEmpty || (words.length == 1 && !atNewWord)) {
      return _commands(
        words.isEmpty ? '' : words.first,
        usage,
        edition,
        includeMinecraftCommands,
        includeBridgeManagement,
        bridgeCapabilities,
      );
    }

    final command = MinecraftCommands.byName(
      edition,
      includeMinecraftCommands: includeMinecraftCommands,
      includeBridgeManagement: includeBridgeManagement,
      bridgeCapabilities: bridgeCapabilities,
    )[words.first.toLowerCase()];
    if (command == null) return const [];

    // Index of the argument being typed, counting from after the command name.
    final argIndex = atNewWord ? words.length - 1 : words.length - 2;
    final prefix = atNewWord ? '' : words.last;

    if (command.name == 'admincraft' && argIndex == 1) {
      if (words.length <= 1 || words[1].toLowerCase() != 'logs') {
        return const [];
      }
      const counts = ['50', '100', '250', '500', '1000'];
      return counts
          .where((value) => value.startsWith(prefix))
          .map((value) => Completion(value, 'log lines', ArgType.number))
          .toList();
    }

    final arg = command.argAt(argIndex);
    if (arg == null) return const [];

    return _forArg(arg, prefix, onlinePlayers, edition);
  }

  /// The command whose syntax should be displayed for [input], if any.
  static BedrockCommand? commandFor(
    String input, {
    MinecraftEdition edition = MinecraftEdition.bedrock,
    bool includeMinecraftCommands = true,
    bool includeBridgeManagement = false,
    Set<String>? bridgeCapabilities,
  }) {
    final words = input
        .trimLeft()
        .split(RegExp(r'\s+'))
        .where((w) => w.isNotEmpty)
        .toList();
    if (words.isEmpty) return null;
    return MinecraftCommands.byName(
      edition,
      includeMinecraftCommands: includeMinecraftCommands,
      includeBridgeManagement: includeBridgeManagement,
      bridgeCapabilities: bridgeCapabilities,
    )[words.first.toLowerCase()];
  }

  /// Returns the first required argument that has not been entered. Unknown
  /// commands remain allowed because servers and plugins can add commands not
  /// present in Admincraft's built-in catalogue.
  static CommandArg? missingRequiredArgument(
    String input, {
    MinecraftEdition edition = MinecraftEdition.bedrock,
    bool includeMinecraftCommands = true,
    bool includeBridgeManagement = false,
    Set<String>? bridgeCapabilities,
  }) {
    final words = input
        .trim()
        .split(RegExp(r'\s+'))
        .where((word) => word.isNotEmpty)
        .toList();
    if (words.isEmpty) return null;
    final command = MinecraftCommands.byName(
      edition,
      includeMinecraftCommands: includeMinecraftCommands,
      includeBridgeManagement: includeBridgeManagement,
      bridgeCapabilities: bridgeCapabilities,
    )[words.first.toLowerCase()];
    if (command == null) return null;

    final supplied = words.length - 1;
    for (var index = supplied; index < command.args.length; index++) {
      if (command.args[index].required) return command.args[index];
    }
    return null;
  }

  /// Which argument index [input] is currently on, for highlighting the hint.
  static int activeArgIndex(String input) {
    final atNewWord = input.isEmpty || input.endsWith(' ');
    final words = input
        .trimLeft()
        .split(RegExp(r'\s+'))
        .where((w) => w.isNotEmpty)
        .toList();
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

  static List<Completion> _commands(
    String prefix,
    Map<String, int> usage,
    MinecraftEdition edition,
    bool includeMinecraftCommands,
    bool includeBridgeManagement,
    Set<String>? bridgeCapabilities,
  ) {
    return _rank(
      MinecraftCommands.all(
        edition,
        includeMinecraftCommands: includeMinecraftCommands,
        includeBridgeManagement: includeBridgeManagement,
        bridgeCapabilities: bridgeCapabilities,
      ).map((c) => Completion(c.name, c.description)).toList(),
      prefix,
      usage: usage,
    );
  }

  static List<Completion> _forArg(
    CommandArg arg,
    String prefix,
    Set<String> onlinePlayers,
    MinecraftEdition edition,
  ) {
    switch (arg.type) {
      case ArgType.literal:
        return _rank(
          arg.options.map((o) => Completion(o, '', ArgType.literal)).toList(),
          prefix,
        );
      case ArgType.player:
        return _rank(
          onlinePlayers
              .map((player) => Completion(player, 'online', ArgType.player))
              .toList(),
          prefix,
        );
      case ArgType.item:
        return _rank(
          BedrockIds.items.map((i) => Completion(i, '', ArgType.item)).toList(),
          prefix,
        );
      case ArgType.entity:
        return _rank(
          BedrockIds.entities
              .map((e) => Completion(e, '', ArgType.entity))
              .toList(),
          prefix,
        );
      case ArgType.effect:
        return _rank(
          BedrockIds.effects
              .map((e) => Completion(e, '', ArgType.effect))
              .toList(),
          prefix,
        );
      case ArgType.enchantment:
        return _rank(
          BedrockIds.enchantments
              .map((e) => Completion(e, '', ArgType.enchantment))
              .toList(),
          prefix,
        );
      case ArgType.gamerule:
        final gamerules = edition == MinecraftEdition.java
            ? JavaIds.gamerules
            : BedrockIds.gamerules;
        return _rank(
          gamerules
              .map(
                (g) => Completion(
                  g,
                  BedrockGamerules.forName(g).label,
                  ArgType.gamerule,
                ),
              )
              .toList(),
          prefix,
        );
      case ArgType.number:
        const commonAmounts = ['1', '5', '10', '20', '64', '128'];
        final amounts = arg.options.isEmpty ? commonAmounts : arg.options;
        return amounts
            .where((value) => value.startsWith(prefix))
            .map((value) => Completion(value, 'amount', ArgType.number))
            .toList();
      case ArgType.text:
      case ArgType.position:
        return const [];
    }
  }

  /// Prefix matches first, then matches anywhere, so typing "sword" still
  /// finds "diamond_sword" while "diamond" keeps the diamond items on top.
  ///
  /// Within each group the most used entries come first, so the commands
  /// someone actually reaches for rise to the front of the strip. Ordering is
  /// applied inside the groups rather than across them: a frequently used
  /// command should never outrank something the user is literally typing.
  static List<Completion> _rank(
    List<Completion> candidates,
    String prefix, {
    Map<String, int> usage = const {},
  }) {
    int byUsage(Completion a, Completion b) {
      final used =
          (usage[b.value.toLowerCase()] ?? 0) -
          (usage[a.value.toLowerCase()] ?? 0);
      return used != 0 ? used : a.value.compareTo(b.value);
    }

    if (prefix.isEmpty) {
      final all = [...candidates]..sort(byUsage);
      return all.take(_limit).toList();
    }

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

    starts.sort(byUsage);
    contains.sort(byUsage);

    return [...starts, ...contains].take(_limit).toList();
  }

  static const int _limit = 40;
}
