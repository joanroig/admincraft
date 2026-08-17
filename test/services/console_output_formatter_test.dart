import 'package:admincraft/services/console_output_formatter.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('routine server noise is hidden conservatively by default', () {
    const output = '''
[2026-08-16 17:00:00:000 INFO] Running AutoCompaction...
[2026-08-16 17:00:01:000 INFO] There are 0/10 players online:
[2026-08-16 17:00:01:100 INFO] Daytime is 7000
[2026-08-16 17:00:01:200 INFO] keepInventory = true
Admincraft connected to bedrock bridge (commands, logs, restart)
[2026-08-16 17:00:02:000 WARN] Keepalive timeout
''';

    final lines = ConsoleOutputFormatter.visibleLines(
      output,
      hideCommonNoise: true,
    );

    expect(lines, hasLength(1));
    expect(lines.join('\n'), isNot(contains('AutoCompaction')));
    expect(lines.join('\n'), isNot(contains('players online')));
    expect(lines.join('\n'), isNot(contains('Daytime')));
    expect(lines.join('\n'), isNot(contains('keepInventory')));
    expect(lines.join('\n'), isNot(contains('connected to bedrock bridge')));
    expect(lines.join('\n'), contains('Keepalive timeout'));
  });

  test('noise can be restored and text filtering remains available', () {
    const output = 'Running AutoCompaction...\nPlayer joined\n';

    expect(
      ConsoleOutputFormatter.visibleLines(
        output,
        hideCommonNoise: false,
        containing: 'auto',
      ),
      ['Running AutoCompaction...'],
    );
  });

  test('timestamp formatting is shared across server output surfaces', () {
    const line = '[2026-08-16 17:03:22:125 INFO] Server ready';

    expect(ConsoleOutputFormatter.formatLine(line, 'hidden'), 'Server ready');
    expect(
      ConsoleOutputFormatter.formatLine(line, 'short'),
      '[17:03 INFO] Server ready',
    );
    expect(ConsoleOutputFormatter.formatLine(line, 'full'), line);
  });

  test('ANSI colors and terminal control bytes are never rendered', () {
    const decorated = '\x1B[37mDEBUG\x1B[0m[7944] Forwarding signal\x00\x07';

    expect(
      ConsoleOutputFormatter.formatLine(decorated, 'full'),
      'DEBUG[7944] Forwarding signal',
    );
    expect(
      ConsoleOutputFormatter.visibleLines(
        '$decorated\n',
        hideCommonNoise: false,
      ),
      ['DEBUG[7944] Forwarding signal'],
    );
  });

  test(
    'locally echoed commands retain identity without rendering a marker',
    () {
      final marked = ConsoleOutputFormatter.markUserCommand('admincraft help');

      expect(ConsoleOutputFormatter.isUserCommand(marked), isTrue);
      expect(
        ConsoleOutputFormatter.formatLine(marked, 'hidden'),
        'admincraft help',
      );
      expect(ConsoleOutputFormatter.isUserCommand('admincraft help'), isFalse);
    },
  );
}
