import 'package:admincraft/models/model.dart';
import 'package:admincraft/services/persistence_service.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  test(
    'legacy bridge only advertises the management command it supports',
    () async {
      SharedPreferences.setMockInitialValues({});
      final preferences = await SharedPreferences.getInstance();
      final model = Model(PersistenceService(preferences));

      model.markLegacyBridgeConnected();

      expect(model.advertisedBridgeCommandCapabilities, {'restart'});
    },
  );

  test('current bridge exposes its full command capability set', () async {
    SharedPreferences.setMockInitialValues({});
    final preferences = await SharedPreferences.getInstance();
    final model = Model(PersistenceService(preferences));

    model.updateBridgeHello(
      protocol: 2,
      capabilities: const {'help', 'logs', 'status', 'version'},
    );

    expect(model.advertisedBridgeCommandCapabilities, {
      'help',
      'logs',
      'status',
      'version',
    });
  });
}
