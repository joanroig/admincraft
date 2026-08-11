class CommandUtils {
  /// Mirrors the validation the Admincraft WebSocket server applies before
  /// running a command. Checking it here turns a bare "Invalid input." reply
  /// from the server into a message that explains what was wrong.
  static final RegExp _accepted = RegExp(r'^[a-zA-Z0-9_\- ]+$');

  static bool isAccepted(String command) => _accepted.hasMatch(command);

  static const String rejectionMessage =
      'The server only accepts letters, digits, spaces, underscores and hyphens in commands.';
}
