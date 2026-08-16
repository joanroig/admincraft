import 'package:admincraft/models/minecraft_edition.dart';
import 'package:admincraft/models/model.dart';
import 'package:admincraft/services/persistence_service.dart';
import 'package:admincraft/services/quiet_command_filter.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  test('status probes hide only their matching replies', () {
    final filter = QuietCommandFilter();
    filter.expect('time query daytime', MinecraftEdition.bedrock);
    filter.expect('list', MinecraftEdition.bedrock);

    expect(filter.shouldHide('A player joined the game'), isFalse);
    expect(filter.shouldHide('[INFO] Daytime is 1200'), isTrue);
    expect(filter.shouldHide('[INFO] There are 2/10 players online:'), isTrue);
    expect(filter.shouldHide('Alex, Steve'), isTrue);
    expect(filter.shouldHide('[WARN] Keepalive timeout'), isFalse);
  });

  test('queried gamerules are quiet without hiding unrelated rules', () {
    final filter = QuietCommandFilter();
    filter.expect('gamerule keepInventory', MinecraftEdition.bedrock);

    expect(filter.shouldHide('[INFO] doDaylightCycle = true'), isFalse);
    expect(filter.shouldHide('[INFO] keepInventory = false'), isTrue);
  });

  test('hidden status replies still update the world model', () async {
    SharedPreferences.setMockInitialValues({});
    final preferences = await SharedPreferences.getInstance();
    final model = Model(PersistenceService(preferences));

    model.appendOutputCommand('[INFO] Daytime is 6000', visible: false);
    model.appendOutputCommand(
      '[INFO] There are 0/10 players online:',
      visible: false,
    );

    expect(model.world.daytime, 6000);
    expect(model.world.playersOnline, 0);
    expect(model.output, isEmpty);
  });
}
