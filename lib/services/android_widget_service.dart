import 'package:admincraft/models/server_profile.dart';
import 'package:admincraft/models/world_state.dart';
import 'package:flutter/services.dart';
import 'package:flutter/foundation.dart';

class AndroidWidgetService {
  static const _channel = MethodChannel('admincraft/server-widget');

  static Future<void> update(ServerProfile server, WorldState world) async {
    if (kIsWeb || defaultTargetPlatform != TargetPlatform.android) return;
    try {
      await _channel.invokeMethod<void>('update', {
        'alias': server.alias,
        'players': world.playersOnline,
        'limit': world.playerLimit,
      });
    } on MissingPluginException {
      // Only Android installs the widget channel.
    } on PlatformException {
      // A home-screen widget is optional and must never interrupt the app.
    } catch (_) {
      // Pure Dart tests and early startup may not have a channel binding yet.
    }
  }
}
