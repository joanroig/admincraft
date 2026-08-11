import 'package:admincraft/controllers/connection_controller.dart';
import 'package:admincraft/models/connection_status.dart';
import 'package:admincraft/models/model.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

class OverviewView extends StatelessWidget {
  final VoidCallback onOpenConsole;
  final VoidCallback onOpenControls;
  final VoidCallback onEditServer;

  const OverviewView({
    super.key,
    required this.onOpenConsole,
    required this.onOpenControls,
    required this.onEditServer,
  });

  @override
  Widget build(BuildContext context) {
    final model = context.watch<Model>();
    final connection = context.watch<ConnectionController>();
    final connected = connection.status == ConnectionStatus.connected;
    final world = model.world;
    final outputLines = model.output
        .split('\n')
        .where((line) => line.trim().isNotEmpty)
        .toList();
    final recentLines = outputLines.length <= 4
        ? outputLines.reversed.toList()
        : outputLines.sublist(outputLines.length - 4).reversed.toList();

    return _PageFrame(
      title: 'Overview',
      subtitle: 'The current state of ${model.alias}.',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (!model.selectedServer.isComplete)
            _SetupBanner(onEditServer: onEditServer)
          else if (!connected)
            const Card(
              child: ListTile(
                leading: Icon(Icons.cloud_off_outlined),
                title: Text('Server is disconnected'),
                subtitle: Text(
                  'Connect from the header to load players and world state.',
                ),
              ),
            ),
          const SizedBox(height: 12),
          LayoutBuilder(
            builder: (context, constraints) {
              final columns = constraints.maxWidth >= 720 ? 3 : 1;
              const spacing = 12.0;
              final width =
                  (constraints.maxWidth - spacing * (columns - 1)) / columns;
              return Wrap(
                spacing: spacing,
                runSpacing: spacing,
                children: [
                  _MetricCard(
                    width: width,
                    icon: Icons.people_outline,
                    label: 'Players',
                    value: world.playersOnline == null
                        ? '${model.onlinePlayers.length} tracked'
                        : '${world.playersOnline} of ${world.playerLimit}',
                  ),
                  _MetricCard(
                    width: width,
                    icon: world.timeIcon,
                    label: 'World time',
                    value: '${world.timeLabel} · ${world.clock}',
                  ),
                  _MetricCard(
                    width: width,
                    icon: Icons.shield_outlined,
                    label: 'Difficulty',
                    value: world.lastDifficulty ?? 'Not observed yet',
                  ),
                ],
              );
            },
          ),
          const SizedBox(height: 16),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(18),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Quick actions',
                      style: Theme.of(context).textTheme.titleMedium),
                  const SizedBox(height: 4),
                  Text(
                    'Common server tasks stay together instead of being scattered through settings.',
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                  const SizedBox(height: 14),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      FilledButton.icon(
                        onPressed: onOpenConsole,
                        icon: const Icon(Icons.terminal),
                        label: const Text('Open console'),
                      ),
                      OutlinedButton.icon(
                        onPressed: onOpenControls,
                        icon: const Icon(Icons.tune),
                        label: const Text('Server controls'),
                      ),
                      OutlinedButton.icon(
                        onPressed: onEditServer,
                        icon: const Icon(Icons.edit_outlined),
                        label: const Text('Edit server'),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(18),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text('Recent activity',
                            style: Theme.of(context).textTheme.titleMedium),
                      ),
                      TextButton(
                        onPressed: onOpenConsole,
                        child: const Text('View console'),
                      ),
                    ],
                  ),
                  if (recentLines.isEmpty)
                    Padding(
                      padding: const EdgeInsets.symmetric(vertical: 18),
                      child: Text(
                        connected
                            ? 'Waiting for server output…'
                            : 'Connect to see server activity.',
                        style: Theme.of(context).textTheme.bodySmall,
                      ),
                    )
                  else
                    for (final line in recentLines)
                      ListTile(
                        contentPadding: EdgeInsets.zero,
                        dense: true,
                        leading: const Icon(Icons.chevron_right, size: 18),
                        title: Text(
                          line,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _PageFrame extends StatelessWidget {
  final String title;
  final String subtitle;
  final Widget child;

  const _PageFrame({
    required this.title,
    required this.subtitle,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 1040),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(title, style: Theme.of(context).textTheme.headlineMedium),
              const SizedBox(height: 4),
              Text(subtitle, style: Theme.of(context).textTheme.bodyMedium),
              const SizedBox(height: 12),
              child,
            ],
          ),
        ),
      ),
    );
  }
}

class _SetupBanner extends StatelessWidget {
  final VoidCallback onEditServer;

  const _SetupBanner({required this.onEditServer});

  @override
  Widget build(BuildContext context) {
    return Card(
      color: Theme.of(context).colorScheme.primaryContainer,
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Row(
          children: [
            const Icon(Icons.rocket_launch_outlined),
            const SizedBox(width: 14),
            const Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Finish setting up this server'),
                  SizedBox(height: 3),
                  Text('Add its address and secret key before connecting.'),
                ],
              ),
            ),
            FilledButton(
              onPressed: onEditServer,
              child: const Text('Set up'),
            ),
          ],
        ),
      ),
    );
  }
}

class _MetricCard extends StatelessWidget {
  final double width;
  final IconData icon;
  final String label;
  final String value;

  const _MetricCard({
    required this.width,
    required this.icon,
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: width,
      child: Card(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Icon(icon, color: Theme.of(context).colorScheme.primary),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(label, style: Theme.of(context).textTheme.bodySmall),
                    const SizedBox(height: 4),
                    Text(
                      value,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
