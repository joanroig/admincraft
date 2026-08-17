import 'package:admincraft/controllers/connection_controller.dart';
import 'package:admincraft/models/connection_status.dart';
import 'package:admincraft/models/model.dart';
import 'package:admincraft/services/console_output_formatter.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

class OverviewView extends StatelessWidget {
  final VoidCallback onOpenConsole;
  final VoidCallback onEditServer;

  const OverviewView({
    super.key,
    required this.onOpenConsole,
    required this.onEditServer,
  });

  @override
  Widget build(BuildContext context) {
    final model = context.watch<Model>();
    final connection = context.watch<ConnectionController>();
    final connected = connection.status == ConnectionStatus.connected;
    final compatibilityFailure = connection.compatibilityFailure(model);
    final world = model.world;
    final outputLines = ConsoleOutputFormatter.visibleLines(
      model.output,
      hideCommonNoise: model.hideCommonConsoleNoise,
      containing: model.consoleFilterPattern,
    );
    final recentLines = outputLines.length <= 4
        ? outputLines.reversed.toList()
        : outputLines.sublist(outputLines.length - 4).reversed.toList();

    return _PageFrame(
      title: 'Overview',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (!model.selectedServer.isComplete)
            _SetupBanner(onEditServer: onEditServer)
          else if (compatibilityFailure != null)
            _CompatibilityBanner(
              message: compatibilityFailure.message,
              onEditServer: onEditServer,
            )
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
          _DiagnosticsCard(model: model, connection: connection),
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
                        child: Text(
                          'Recent activity',
                          style: Theme.of(context).textTheme.titleMedium,
                        ),
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
                      Padding(
                        padding: const EdgeInsets.symmetric(vertical: 3),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Padding(
                              padding: EdgeInsets.only(top: 1),
                              child: Icon(Icons.chevron_right, size: 17),
                            ),
                            const SizedBox(width: 5),
                            Expanded(
                              child: Text(
                                ConsoleOutputFormatter.formatLine(
                                  line,
                                  model.consoleTimestampMode,
                                ),
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                                style: TextStyle(
                                  fontFamily: model.terminalFont,
                                  fontFamilyFallback: const [
                                    'Miracode',
                                    'monospace',
                                  ],
                                  fontSize: model.terminalFontSize,
                                  height: 1.25,
                                ),
                              ),
                            ),
                          ],
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

class _DiagnosticsCard extends StatelessWidget {
  final Model model;
  final ConnectionController connection;

  const _DiagnosticsCard({required this.model, required this.connection});

  String _time(DateTime? value) =>
      value == null ? 'Not observed' : value.toLocal().toIso8601String();

  String _diagnosticText() => [
    'Server: ${model.alias}',
    'Endpoint: ${model.ip}:${model.port}',
    'Connection: ${connection.status.name}',
    'Security: ${model.connectionSecurity.name}',
    'Edition: ${model.minecraftEdition.name}',
    'Bridge version: ${model.bridgeVersion ?? 'Unknown'}',
    'Protocol: ${model.bridgeProtocol?.toString() ?? 'Unknown'}',
    'Permission: ${model.bridgePermission ?? 'Unknown'}',
    'Server state: ${model.serverRuntimeState ?? 'Unknown'}',
    'Connected at: ${_time(model.bridgeConnectedAt)}',
    'Last heartbeat: ${_time(model.lastHeartbeatAt)}',
    'Last log: ${_time(model.lastLogAt)}',
    'Last state event: ${_time(model.lastServerStateAt)}',
    'Capabilities: ${model.bridgeCapabilities.join(', ')}',
    if (model.bridgeLastError != null) 'Last error: ${model.bridgeLastError}',
  ].join('\n');

  Future<void> _show(BuildContext context) async {
    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      builder: (sheetContext) => SafeArea(
        child: DraggableScrollableSheet(
          expand: false,
          initialChildSize: 0.72,
          maxChildSize: 0.92,
          builder: (context, controller) => ListView(
            controller: controller,
            padding: const EdgeInsets.fromLTRB(20, 0, 20, 24),
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(
                      'Connection diagnostics',
                      style: Theme.of(context).textTheme.titleLarge,
                    ),
                  ),
                  TextButton.icon(
                    onPressed: () async {
                      await Clipboard.setData(
                        ClipboardData(text: _diagnosticText()),
                      );
                      if (!context.mounted) return;
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Diagnostics copied.')),
                      );
                    },
                    icon: const Icon(Icons.copy_all_outlined),
                    label: const Text('Copy'),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              _DiagnosticRow(
                label: 'Connection',
                value: connection.status.name,
              ),
              _DiagnosticRow(
                label: 'Server state',
                value: model.serverRuntimeState ?? 'Unknown',
              ),
              _DiagnosticRow(
                label: 'Bridge version',
                value: model.bridgeVersion ?? 'Unknown or legacy bridge',
              ),
              _DiagnosticRow(
                label: 'Protocol',
                value: model.bridgeProtocol?.toString() ?? 'Unknown',
              ),
              _DiagnosticRow(
                label: 'Permission',
                value: model.bridgePermission ?? 'Unknown',
              ),
              _DiagnosticRow(
                label: 'Connected',
                value: _time(model.bridgeConnectedAt),
              ),
              _DiagnosticRow(
                label: 'Last heartbeat',
                value: _time(model.lastHeartbeatAt),
              ),
              _DiagnosticRow(label: 'Last log', value: _time(model.lastLogAt)),
              _DiagnosticRow(
                label: 'Last state event',
                value: _time(model.lastServerStateAt),
              ),
              if (model.bridgeLastError != null)
                _DiagnosticRow(
                  label: 'Last error',
                  value: model.bridgeLastError!,
                ),
              const SizedBox(height: 14),
              Text(
                'Capabilities',
                style: Theme.of(context).textTheme.titleMedium,
              ),
              const SizedBox(height: 8),
              if (model.bridgeCapabilities.isEmpty)
                const Text('No capabilities advertised.')
              else
                Wrap(
                  spacing: 6,
                  runSpacing: 6,
                  children: model.bridgeCapabilities
                      .map((capability) => Chip(label: Text(capability)))
                      .toList(),
                ),
              const SizedBox(height: 18),
              Text(
                'Command audit',
                style: Theme.of(context).textTheme.titleMedium,
              ),
              const SizedBox(height: 6),
              if (model.commandAudit.isEmpty)
                const Text('No user-issued commands recorded for this server.')
              else
                for (final entry in model.commandAudit.reversed.take(20))
                  ListTile(
                    dense: true,
                    contentPadding: EdgeInsets.zero,
                    leading: const Icon(Icons.terminal, size: 20),
                    title: Text(entry.command),
                    subtitle: Text(
                      '${entry.source} · ${entry.outcome} · ${_time(entry.occurredAt)}',
                    ),
                  ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      child: ListTile(
        leading: const Icon(Icons.monitor_heart_outlined),
        title: const Text('Diagnostics'),
        subtitle: Text(
          [
            model.serverRuntimeState ?? connection.status.name,
            if (model.bridgeVersion != null) 'bridge v${model.bridgeVersion}',
            if (model.bridgePermission != null) model.bridgePermission!,
          ].join(' · '),
        ),
        trailing: const Icon(Icons.chevron_right),
        onTap: () => _show(context),
      ),
    );
  }
}

class _DiagnosticRow extends StatelessWidget {
  final String label;
  final String value;

  const _DiagnosticRow({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 5),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 130,
            child: Text(label, style: Theme.of(context).textTheme.bodySmall),
          ),
          Expanded(child: SelectableText(value)),
        ],
      ),
    );
  }
}

class _CompatibilityBanner extends StatelessWidget {
  final String message;
  final VoidCallback onEditServer;

  const _CompatibilityBanner({
    required this.message,
    required this.onEditServer,
  });

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Card(
      color: scheme.errorContainer,
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(
                  Icons.browser_not_supported,
                  color: scheme.onErrorContainer,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'This connection is not available in the browser',
                        style: Theme.of(context).textTheme.titleMedium
                            ?.copyWith(color: scheme.onErrorContainer),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        message,
                        style: TextStyle(color: scheme.onErrorContainer),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Align(
              alignment: Alignment.centerRight,
              child: FilledButton(
                onPressed: onEditServer,
                child: const Text('Review connection'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _PageFrame extends StatelessWidget {
  final String title;
  final Widget child;

  const _PageFrame({required this.title, required this.child});

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
            FilledButton(onPressed: onEditServer, child: const Text('Set up')),
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
