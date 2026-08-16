import 'package:admincraft/utils/host_utils.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  // What people paste is a URL, because that is what every guide gives them.
  // Stored verbatim it became wss://https://host, which fails with nothing on
  // screen to explain it.
  test('a pasted URL is reduced to its host', () {
    final parsed = HostInput.parse('https://admincraft.tail4e1785.ts.net');

    expect(parsed.host, 'admincraft.tail4e1785.ts.net');
    expect(parsed.hadScheme, isTrue);
    expect(parsed.port, isNull);
  });

  test('a port in the address moves to the port field', () {
    final parsed = HostInput.parse('wss://example.com:8443/socket');

    expect(parsed.host, 'example.com');
    expect(parsed.port, 8443);
    expect(parsed.hadPath, isTrue);
  });

  test('a bare host is left exactly as it is', () {
    final parsed = HostInput.parse('  100.64.0.1  ');

    expect(parsed.host, '100.64.0.1');
    expect(parsed.port, isNull);
    expect(parsed.wasCleaned, isFalse);
  });

  // A colon in an IPv6 address separates groups, not a port, so the address
  // must survive intact unless it is bracketed and followed by one.
  test('IPv6 keeps its colons', () {
    expect(HostInput.parse('[fd7a::1]').host, '[fd7a::1]');
    expect(HostInput.parse('fd7a::1').host, 'fd7a::1');

    final withPort = HostInput.parse('[fd7a::1]:8080');
    expect(withPort.host, '[fd7a::1]');
    expect(withPort.port, 8080);
  });

  test('a port outside the valid range stays part of the host', () {
    // Otherwise a typo silently becomes a port number nobody chose.
    expect(HostInput.parse('example.com:99999').port, isNull);
  });

  test('credentials are not treated as the host', () {
    expect(HostInput.parse('https://user:pass@example.com').host, 'example.com');
  });
}
