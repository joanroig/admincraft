/// What a command argument accepts, which decides where completions come from.
enum ArgType {
  /// A fixed set of literal values, carried in [CommandArg.options].
  literal,

  /// A player name. Completed from players seen connecting to the server.
  player,

  /// An item or block identifier.
  item,

  /// An entity identifier.
  entity,

  /// A status effect identifier.
  effect,

  /// An enchantment identifier.
  enchantment,

  /// A game rule name.
  gamerule,

  /// A number. No completions, but still shown in the syntax hint.
  number,

  /// Free text, such as a chat message. Always the last argument.
  text,

  /// Coordinates. No completions.
  position,
}

class CommandArg {
  final String name;
  final ArgType type;
  final bool required;

  /// Values for [ArgType.literal].
  final List<String> options;

  const CommandArg(
    this.name,
    this.type, {
    this.required = true,
    this.options = const [],
  });

  /// Rendered the way Minecraft documents arguments: `<required>`, `[optional]`.
  String get hint => required ? '<$name>' : '[$name]';
}

class BedrockCommand {
  final String name;
  final String description;
  final String category;
  final List<CommandArg> args;

  const BedrockCommand(
    this.name,
    this.description,
    this.category, {
    this.args = const [],
  });

  /// The full syntax, for example `give <player> <item> [amount]`.
  String get syntax => [name, ...args.map((arg) => arg.hint)].join(' ');

  /// The argument at [index], or null past the end. The final [ArgType.text]
  /// argument keeps matching, since a message runs to the end of the line.
  CommandArg? argAt(int index) {
    if (args.isEmpty) return null;
    if (index < args.length) return args[index];
    final last = args.last;
    return last.type == ArgType.text ? last : null;
  }
}
