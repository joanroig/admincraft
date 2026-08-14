import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:admincraft/services/rcon_connection.dart';

/// Native platforms can open the raw TCP socket RCON needs.
const bool supportsDirectRcon = true;

// Packet types from the Source RCON protocol, which Minecraft implements.
const int _typeAuth = 3;
const int _typeCommand = 2;

/// Opens an RCON session and authenticates it.
///
/// Throws [RconAuthException] if the password is refused, and lets socket
/// errors propagate so the caller can tell "wrong password" from "nothing
/// listening there".
Future<RconConnection> connectRcon({
  required String host,
  required int port,
  required String password,
  Duration timeout = const Duration(seconds: 10),
}) async {
  final socket = await Socket.connect(host, port, timeout: timeout);
  socket.setOption(SocketOption.tcpNoDelay, true);

  final connection = _SocketRconConnection(socket);
  await connection._authenticate(password, timeout);
  return connection;
}

class _SocketRconConnection implements RconConnection {
  final Socket _socket;
  final _responses = StreamController<String>.broadcast();

  /// Packets can be split or coalesced by TCP, so bytes accumulate here until a
  /// whole packet is present.
  final _buffer = BytesBuilder();

  /// Ids are echoed back, which is how an auth failure is recognised: the
  /// server answers with -1 instead of the id that was sent.
  int _nextId = 1;

  Completer<bool>? _authResult;

  _SocketRconConnection(this._socket) {
    _socket.listen(
      _onData,
      onError: (Object error) => _responses.addError(error),
      onDone: _responses.close,
      cancelOnError: false,
    );
  }

  @override
  Stream<String> get responses => _responses.stream;

  Future<void> _authenticate(String password, Duration timeout) async {
    final result = _authResult = Completer<bool>();
    _write(_typeAuth, password);

    final accepted = await result.future.timeout(
      timeout,
      onTimeout: () => throw const RconAuthException(),
    );
    _authResult = null;

    if (!accepted) {
      await close();
      throw const RconAuthException();
    }
  }

  @override
  void send(String command) => _write(_typeCommand, command);

  void _write(int type, String body) {
    final payload = ascii.encode(body);
    // Length covers everything after itself: two ints, the body, and the two
    // terminating nulls the protocol requires.
    final length = 4 + 4 + payload.length + 2;

    final packet = ByteData(4 + length);
    packet.setInt32(0, length, Endian.little);
    packet.setInt32(4, _nextId++, Endian.little);
    packet.setInt32(8, type, Endian.little);

    final bytes = packet.buffer.asUint8List();
    bytes.setRange(12, 12 + payload.length, payload);
    // Trailing nulls are already zero from the fresh buffer.

    _socket.add(bytes);
  }

  void _onData(Uint8List chunk) {
    _buffer.add(chunk);
    var bytes = _buffer.toBytes();
    var offset = 0;

    while (bytes.length - offset >= 4) {
      final view = ByteData.sublistView(bytes, offset);
      final length = view.getInt32(0, Endian.little);
      if (bytes.length - offset - 4 < length) break;

      final id = view.getInt32(4, Endian.little);
      final bodyBytes = bytes.sublist(offset + 12, offset + 4 + length - 2);
      offset += 4 + length;

      final pending = _authResult;
      if (pending != null && !pending.isCompleted) {
        // -1 is the protocol's way of saying the password was wrong.
        pending.complete(id != -1);
        continue;
      }

      final body = ascii.decode(bodyBytes, allowInvalid: true);
      if (body.isNotEmpty) _responses.add(body);
    }

    // Keep whatever is left of a partial packet for the next chunk.
    _buffer.clear();
    if (offset < bytes.length) _buffer.add(bytes.sublist(offset));
  }

  @override
  Future<void> close() async {
    await _socket.close();
    _socket.destroy();
    if (!_responses.isClosed) await _responses.close();
  }
}
