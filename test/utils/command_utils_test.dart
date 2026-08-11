import 'package:admincraft/utils/command_utils.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('accepts normal Minecraft selector and namespace syntax', () {
    expect(CommandUtils.isAccepted('give @a minecraft:stone 1'), isTrue);
    expect(CommandUtils.isAccepted('say Olá, miners!'), isTrue);
  });

  test('rejects control characters and oversized commands', () {
    expect(CommandUtils.isAccepted('say first\nstop'), isFalse);
    expect(CommandUtils.isAccepted(''), isFalse);
    expect(CommandUtils.isAccepted('a' * 2049), isFalse);
  });
}
