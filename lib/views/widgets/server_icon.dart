import 'dart:convert';
import 'dart:typed_data';

import 'package:admincraft/models/server_profile.dart';
import 'package:flutter/material.dart';

const serverIconAssets = <String>[
  'docs/logo/variants/dirt.png',
  'docs/logo/variants/grass.png',
  'docs/logo/variants/creeper.png',
  'docs/logo/variants/diamond.png',
  'docs/logo/variants/obsidian_glow.png',
  'docs/logo/variants/pig.png',
  'docs/logo/variants/gold.png',
  'docs/logo/variants/stone.png',
  'docs/logo/variants/cow.png',
  'docs/logo/variants/villager.png',
  'docs/logo/variants/drowned.png',
  'docs/logo/variants/zombie.png',
  'docs/logo/variants/enderman.png',
];

class ServerIcon extends StatelessWidget {
  final ServerProfile server;
  final double size;

  const ServerIcon({super.key, required this.server, this.size = 32});

  @override
  Widget build(BuildContext context) {
    final custom = _customBytes(server.customIconBase64);
    if (custom != null) {
      return Image.memory(
        custom,
        width: size,
        height: size,
        fit: BoxFit.fill,
        filterQuality: FilterQuality.none,
        gaplessPlayback: true,
      );
    }
    return Image.asset(
      server.iconAsset.isEmpty ? serverIconAssets.first : server.iconAsset,
      width: size,
      height: size,
      fit: BoxFit.fill,
      filterQuality: FilterQuality.none,
      isAntiAlias: false,
      errorBuilder: (_, __, ___) => Icon(Icons.dns_outlined, size: size),
    );
  }

  static Uint8List? _customBytes(String encoded) {
    if (encoded.isEmpty) return null;
    try {
      return base64Decode(encoded);
    } catch (_) {
      return null;
    }
  }
}
