import 'package:admincraft/controllers/connection_controller.dart';
import 'package:admincraft/models/model.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

class ControlTab extends StatelessWidget {
  final bool isEnabled;
  const ControlTab({super.key, required this.isEnabled});

  @override
  Widget build(BuildContext context) {
    final model = Provider.of<Model>(context);
    final connection = Provider.of<ConnectionController>(context);

    if (!isEnabled) {
      return const Center(
        child: Text('Connect to enable the Control Panel'),
      );
    }

    return Center(
      child: ElevatedButton(
        onPressed: () async {
          await connection.restartServer(model);
        },
        child: const Text('Restart Server'),
      ),
    );
  }
}
