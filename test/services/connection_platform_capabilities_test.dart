import 'package:admincraft/models/connection_security.dart';
import 'package:admincraft/models/minecraft_edition.dart';
import 'package:admincraft/services/connection_failure.dart';
import 'package:admincraft/services/connection_platform_capabilities.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  const browser = ConnectionPlatformCapabilities(
    supportsCustomCertificates: false,
    supportsDirectRcon: false,
  );

  test('browser rejects a synced self-signed profile without rewriting it', () {
    final failure = browser.failureFor(
      ConnectionSecurity.customCertificate,
      MinecraftEdition.bedrock,
    );

    expect(failure?.kind, ConnectionFailureKind.unsupported);
    expect(
      failure?.message,
      contains('cannot use the self-signed certificate'),
    );
    expect(failure?.message, contains('Keep this profile for Android'));
    expect(failure?.message, contains('add a separate server profile'));
  });

  test('browser accepts a profile that uses browser-managed trust', () {
    expect(
      browser.failureFor(
        ConnectionSecurity.trustedCertificate,
        MinecraftEdition.bedrock,
      ),
      isNull,
    );
  });
}
