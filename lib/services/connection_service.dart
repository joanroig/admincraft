import 'dart:async';

import 'package:admincraft/models/model.dart';
import 'package:admincraft/utils/toast_utils.dart';
import 'package:dartssh2/dartssh2.dart';

class ConnectionService {
  SSHClient? sshClient;
  bool _isLogging = false;
  StreamSubscription<List<int>>? _logSubscription;
  Timer? _connectionCheckTimer;

  Future<void> connectAndFetchLogs(Model model) async {
    try {
      sshClient = SSHClient(
        await SSHSocket.connect(model.hostname, model.port),
        username: model.username,
        identities: SSHKeyPair.fromPem(model.pemKeyContent),
      );
      model.clearUserCommands();
      await executeCommand('echo Connected!');
    } catch (e) {
      ToastUtils.showToastError(e.toString());
      sshClient = null;
    }
  }

  Future<void> disconnect() async {
    sshClient?.close();
    sshClient = null;
  }

  Future<void> streamLogs(Model model) async {
    if (sshClient == null || _isLogging) return;

    _isLogging = true;

    try {
      final session = await sshClient!.execute('sudo docker compose logs -f');
      _logSubscription = session.stdout.listen(
        (data) {
          final logLine = String.fromCharCodes(data);
          model.appendOutputCommand(logLine);
        },
        onError: (error) {
          ToastUtils.showToastError(error.toString());
          disconnect();
        },
        onDone: () {
          _isLogging = false;
          disconnect();
        },
        cancelOnError: true,
      );
    } catch (e) {
      ToastUtils.showToastError(e.toString());
    }
  }

  Future<String> executeCommand(String command) async {
    return executeCommandWithPrefix(command, "");
  }

  Future<String> executeCommandWithPrefix(String command, String prefix) async {
    try {
      if (sshClient == null) {
        throw Exception("SSH client is not connected");
      }

      String fullCommand = prefix.isNotEmpty ? "$prefix $command" : command;

      final session = await sshClient!.execute(fullCommand).timeout(const Duration(seconds: 5));
      final outputBuffer = <int>[];

      await for (var chunk in session.stdout.timeout(const Duration(seconds: 5), onTimeout: (_) {
        session.close();
        disconnect();
        throw TimeoutException('The command timed out');
      })) {
        outputBuffer.addAll(chunk);
      }

      session.close();
      return String.fromCharCodes(outputBuffer);
    } catch (e) {
      disconnect();
      ToastUtils.showToastError(e.toString());
      return "";
    }
  }

  void startConnectionCheck() {
    _connectionCheckTimer = Timer.periodic(const Duration(seconds: 10), (timer) async {
      if (sshClient == null) {
        timer.cancel();
        return;
      }
      try {
        final result = await executeCommand('echo alive');
        if (result.isEmpty) {
          await disconnect();
        }
      } catch (e) {
        await disconnect();
      }
    });
  }

  void stopConnections() {
    _connectionCheckTimer?.cancel();
    _logSubscription?.cancel();
  }
}
