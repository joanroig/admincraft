import 'package:flutter/material.dart';

/// Live world state, built from what the server prints to its console.
///
/// Only some of it can be read back. Time, difficulty and game rules answer
/// queries, but there is no portable query form for weather. Weather is
/// therefore remembered from what was last set here rather than guessed.
class WorldState {
  /// Ticks into the Minecraft day, 0-23999, or null if never queried.
  final int? daytime;

  /// Game rule values as reported by the server, keyed by the exact name it
  /// used in its reply.
  final Map<String, String> gamerules;

  final int? playersOnline;
  final int? playerLimit;

  /// Weather is set from this app; difficulty is also updated from replies.
  final String? lastWeather;
  final String? lastDifficulty;

  const WorldState({
    this.daytime,
    this.gamerules = const {},
    this.playersOnline,
    this.playerLimit,
    this.lastWeather,
    this.lastDifficulty,
  });

  WorldState copyWith({
    int? daytime,
    Map<String, String>? gamerules,
    int? playersOnline,
    int? playerLimit,
    String? lastWeather,
    String? lastDifficulty,
  }) {
    return WorldState(
      daytime: daytime ?? this.daytime,
      gamerules: gamerules ?? this.gamerules,
      playersOnline: playersOnline ?? this.playersOnline,
      playerLimit: playerLimit ?? this.playerLimit,
      lastWeather: lastWeather ?? this.lastWeather,
      lastDifficulty: lastDifficulty ?? this.lastDifficulty,
    );
  }

  /// Where the sun is, using the tick boundaries the game itself uses:
  /// 0 sunrise, 6000 noon, 12000 sunset, 18000 midnight.
  String get timeLabel {
    final t = daytime;
    if (t == null) return 'Unknown';
    if (t < 1000) return 'Sunrise';
    if (t < 6000) return 'Morning';
    if (t < 9000) return 'Noon';
    if (t < 12000) return 'Afternoon';
    if (t < 13000) return 'Sunset';
    if (t < 18000) return 'Night';
    if (t < 23000) return 'Midnight';
    return 'Sunrise';
  }

  bool get isDay => daytime != null && daytime! < 12000;

  IconData get timeIcon {
    final t = daytime;
    if (t == null) return Icons.help_outline;
    if (t < 1000 || t >= 23000) return Icons.wb_twilight;
    if (t < 12000) return Icons.wb_sunny;
    if (t < 13000) return Icons.wb_twilight;
    return Icons.nightlight_round;
  }

  /// Clock reading for the tick count. Minecraft day 0 starts at 06:00.
  String get clock {
    final t = daytime;
    if (t == null) return '--:--';
    final minutes = ((t / 1000.0) * 60 + 6 * 60).round() % (24 * 60);
    final h = (minutes ~/ 60).toString().padLeft(2, '0');
    final m = (minutes % 60).toString().padLeft(2, '0');
    return '$h:$m';
  }
}
