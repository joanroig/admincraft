class CommandUtils {
  static const int _maxLength = 2048;
  static final RegExp _controlCharacters = RegExp(r'[\u0000-\u001f\u007f]');

  /// Commands are passed as one argument to Docker or directly to RCON, so
  /// normal Minecraft syntax such as selectors, namespaces and quoted text is
  /// safe. Line breaks and other control characters remain forbidden.
  static bool isAccepted(String command) =>
      command.trim().isNotEmpty &&
      command.length <= _maxLength &&
      !_controlCharacters.hasMatch(command);

  static const String rejectionMessage =
      'Commands must be a single non-empty line of at most 2048 characters.';
}
