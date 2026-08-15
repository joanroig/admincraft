import 'dart:async';

import 'package:admincraft/controllers/connection_controller.dart';
import 'package:admincraft/controllers/google_drive_sync_controller.dart';
import 'package:admincraft/models/connection_status.dart';
import 'package:admincraft/models/model.dart';
import 'package:admincraft/utils/build_info.dart';
import 'package:admincraft/utils/url_utils.dart';
import 'package:admincraft/views/control_tab_view.dart';
import 'package:admincraft/views/data_sync_view.dart';
import 'package:admincraft/views/more_view.dart';
import 'package:admincraft/views/overview_view.dart';
import 'package:admincraft/views/preferences_view.dart';
import 'package:admincraft/views/server_editor_view.dart';
import 'package:admincraft/views/servers_view.dart';
import 'package:admincraft/views/welcome_view.dart';
import 'package:admincraft/views/terminal_tab_view.dart';
import 'package:admincraft/views/widgets/pixel_backdrop.dart';
import 'package:admincraft/views/widgets/server_switcher.dart';
import 'package:admincraft/views/widgets/theme_logo.dart';
import 'package:flutter/material.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:provider/provider.dart';

enum _WorkspaceDestination {
  overview,
  console,
  controls,
  servers,
  serverEditor,
  dataSync,
  preferences,
  more,
}

extension on _WorkspaceDestination {
  String get label => switch (this) {
        _WorkspaceDestination.overview => 'Overview',
        _WorkspaceDestination.console => 'Console',
        _WorkspaceDestination.controls => 'Controls',
        _WorkspaceDestination.servers => 'Servers',
        _WorkspaceDestination.serverEditor => 'Configuration',
        _WorkspaceDestination.dataSync => 'Data & Sync',
        _WorkspaceDestination.preferences => 'Preferences',
        _WorkspaceDestination.more => 'Settings',
      };

  /// Whether this page is meaningless without a configured server.
  ///
  /// Onboarding is gated on this rather than on a list of pages allowed to
  /// escape it. That list read as though it named the exceptions, but it
  /// silently blocked every destination nobody remembered to add: Servers and
  /// Settings were both missing, so on mobile, where those are the only way
  /// back, leaving the server editor bounced the user to the welcome screen
  /// and the settings hub could not be opened at all.
  bool get needsServer => switch (this) {
        _WorkspaceDestination.overview ||
        _WorkspaceDestination.console ||
        _WorkspaceDestination.controls =>
          true,
        _WorkspaceDestination.servers ||
        _WorkspaceDestination.serverEditor ||
        _WorkspaceDestination.dataSync ||
        _WorkspaceDestination.preferences ||
        _WorkspaceDestination.more =>
          false,
      };

  IconData get icon => switch (this) {
        _WorkspaceDestination.overview => Icons.dashboard_outlined,
        _WorkspaceDestination.console => Icons.terminal,
        _WorkspaceDestination.controls => Icons.tune,
        _WorkspaceDestination.servers => Icons.dns_outlined,
        _WorkspaceDestination.serverEditor => Icons.edit_outlined,
        _WorkspaceDestination.dataSync => Icons.sync_outlined,
        _WorkspaceDestination.preferences => Icons.palette_outlined,
        _WorkspaceDestination.more => Icons.settings_outlined,
      };
}

class Tabs extends StatefulWidget {
  const Tabs({super.key});

  @override
  State<Tabs> createState() => _TabsState();
}

class _TabsState extends State<Tabs> {
  static const double _desktopBreakpoint = 820;
  late Future<void> _initializationFuture;
  late final PageController _pageController;
  final _pageViewKey = GlobalKey();
  _WorkspaceDestination _destination = _WorkspaceDestination.overview;

  @override
  void initState() {
    super.initState();
    _pageController = PageController();
    _initializationFuture = _initialize();
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  Future<void> _initialize() async {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      final model = context.read<Model>();
      final driveSync = context.read<GoogleDriveSyncController>();
      unawaited(
        driveSync.initialize(model, onRemoteApplied: _serversImported),
      );
      if (model.selectedServer.isComplete) {
        context
            .read<ConnectionController>()
            .attemptConnection(model, reconnect: false);
      }
    });
  }

  void _go(_WorkspaceDestination destination) {
    if (_destination == destination) return;
    setState(() => _destination = destination);
    _syncPage();
  }

  /// Moves the page host onto the current destination.
  ///
  /// The host does not always exist when a destination changes: while the
  /// welcome screen is showing there is no PageView, so the jump is skipped and
  /// the view then mounts at the controller's initial page, landing on Overview
  /// however the destination was set. Retrying after the frame covers that.
  void _syncPage() {
    if (_pageController.hasClients) {
      _pageController.jumpToPage(_destination.index);
      return;
    }

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted || !_pageController.hasClients) return;
      if (_pageController.page?.round() == _destination.index) return;
      _pageController.jumpToPage(_destination.index);
    });
  }

  Future<void> _selectServer(String id) async {
    final model = context.read<Model>();
    final connection = context.read<ConnectionController>();
    await connection.disconnect(model);
    await model.selectServer(id);
    if (!mounted) return;
    _go(_WorkspaceDestination.overview);
    if (model.selectedServer.isComplete) {
      await connection.attemptConnection(model);
    }
  }

  /// Edits the blank profile that already exists rather than adding a second
  /// one, so a first-time setup does not leave an unused server behind.
  void _startFirstServer() => _go(_WorkspaceDestination.serverEditor);

  Future<void> _addServer() async {
    final model = context.read<Model>();
    final connection = context.read<ConnectionController>();
    await connection.disconnect(model);
    await model.addServer();
    if (!mounted) return;
    _go(_WorkspaceDestination.serverEditor);
  }

  Future<void> _serverSaved() async {
    final model = context.read<Model>();
    final connection = context.read<ConnectionController>();
    await connection.disconnect(model);
    if (model.selectedServer.isComplete) {
      await connection.attemptConnection(model);
    }
    if (mounted) {
      context.read<GoogleDriveSyncController>().scheduleSync(model);
    }
  }

  Future<void> _serverDeleted() async {
    final model = context.read<Model>();
    final connection = context.read<ConnectionController>();
    await connection.disconnect(model);
    if (!mounted) return;
    _go(_WorkspaceDestination.servers);
    if (model.selectedServer.isComplete) {
      await connection.attemptConnection(model);
    }
    if (mounted) {
      context.read<GoogleDriveSyncController>().scheduleSync(model);
    }
  }

  Future<void> _serversImported() async {
    final model = context.read<Model>();
    final connection = context.read<ConnectionController>();
    await connection.disconnect(model);
    if (model.selectedServer.isComplete) {
      await connection.attemptConnection(model);
    }
    if (mounted) {
      context.read<GoogleDriveSyncController>().scheduleSync(model);
    }
  }

  Widget _pageAt(
    int index,
    Model model,
    ConnectionController connection,
  ) {
    final destination = _WorkspaceDestination.values[index];
    return switch (destination) {
      _WorkspaceDestination.overview => OverviewView(
          onOpenConsole: () => _go(_WorkspaceDestination.console),
          onOpenControls: () => _go(_WorkspaceDestination.controls),
          onEditServer: () => _go(_WorkspaceDestination.serverEditor),
        ),
      _WorkspaceDestination.console => TerminalTab(
          isEnabled: connection.status == ConnectionStatus.connected,
        ),
      _WorkspaceDestination.controls => ControlTab(
          isEnabled: connection.status == ConnectionStatus.connected,
        ),
      _WorkspaceDestination.servers => ServersView(
          onSelect: _selectServer,
          onAdd: _addServer,
          onEditSelected: () => _go(_WorkspaceDestination.serverEditor),
        ),
      _WorkspaceDestination.serverEditor => ServerEditorView(
          key: ValueKey(model.selectedServerId),
          onSaved: _serverSaved,
          onDeleted: _serverDeleted,
          onBack: () => _go(_WorkspaceDestination.servers),
        ),
      _WorkspaceDestination.dataSync =>
        DataSyncView(onServersChanged: _serversImported),
      _WorkspaceDestination.preferences => const PreferencesView(),
      _WorkspaceDestination.more => MoreView(
          onServers: () => _go(_WorkspaceDestination.servers),
          onDataSync: () => _go(_WorkspaceDestination.dataSync),
          onPreferences: () => _go(_WorkspaceDestination.preferences),
          onDocumentation: () => UrlUtils.openDocumentation(),
        ),
    };
  }

  Widget _pageHost(Model model, ConnectionController connection) {
    return PixelBackdrop(
      child: _pages(model, connection),
    );
  }

  Widget _pages(Model model, ConnectionController connection) {
    return PageView.builder(
      key: _pageViewKey,
      controller: _pageController,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: _WorkspaceDestination.values.length,
      itemBuilder: (context, index) => _KeepAlivePage(
        child: _pageAt(index, model, connection),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final model = context.watch<Model>();
    final connection = context.watch<ConnectionController>();

    return FutureBuilder<void>(
      future: _initializationFuture,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }

        // A blank profile always exists, so dropping into the workspace before
        // anything is configured shows a server that cannot possibly connect.
        // Onboard first, and only then reveal the tabs and controls.
        if (!model.onboardingCompleted && _destination.needsServer) {
          return Scaffold(
            body: PixelBackdrop(
              child: WelcomeView(
                onAddServer: _startFirstServer,
                onImport: () => _go(_WorkspaceDestination.dataSync),
                onPreferences: () => _go(_WorkspaceDestination.preferences),
              ),
            ),
          );
        }

        return LayoutBuilder(
          builder: (context, constraints) {
            final desktop = constraints.maxWidth >= _desktopBreakpoint;
            return desktop
                ? _buildDesktop(context, model, connection)
                : _buildMobile(context, model, connection);
          },
        );
      },
    );
  }

  Widget _buildDesktop(
    BuildContext context,
    Model model,
    ConnectionController connection,
  ) {
    return Scaffold(
      body: Row(
        children: [
          SizedBox(
            width: 224,
            child: _WorkspaceSidebar(
              model: model,
              destination: _destination,
              onDestination: _go,
              onSelectServer: _selectServer,
              onAddServer: _addServer,
            ),
          ),
          const VerticalDivider(width: 1),
          Expanded(
            child: Column(
              children: [
                _WorkspaceHeader(
                  destination: _destination,
                  model: model,
                  connection: connection,
                ),
                const Divider(height: 1),
                Expanded(
                  child: _pageHost(model, connection),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMobile(
    BuildContext context,
    Model model,
    ConnectionController connection,
  ) {
    final secondary = {
      _WorkspaceDestination.servers,
      _WorkspaceDestination.serverEditor,
      _WorkspaceDestination.dataSync,
      _WorkspaceDestination.preferences,
    }.contains(_destination);

    return Scaffold(
      appBar: AppBar(
        leading: secondary
            ? IconButton(
                tooltip: _destination == _WorkspaceDestination.serverEditor
                    ? 'Back to Servers'
                    : 'Back to Settings',
                onPressed: () => _go(
                  _destination == _WorkspaceDestination.serverEditor
                      ? _WorkspaceDestination.servers
                      : _WorkspaceDestination.more,
                ),
                icon: const Icon(Icons.arrow_back),
              )
            : null,
        titleSpacing: secondary ? 0 : 12,
        title: secondary
            ? Text(_destination.label)
            : ServerSwitcher(
                model: model,
                compact: true,
                onSelect: _selectServer,
                onAdd: _addServer,
              ),
        actions: [_ConnectionAction(model: model, connection: connection)],
      ),
      body: _pageHost(model, connection),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _mobileIndex,
        onDestinationSelected: (index) => _go(switch (index) {
          0 => _WorkspaceDestination.overview,
          1 => _WorkspaceDestination.console,
          2 => _WorkspaceDestination.controls,
          _ => _WorkspaceDestination.more,
        }),
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.dashboard_outlined),
            selectedIcon: Icon(Icons.dashboard),
            label: 'Overview',
          ),
          NavigationDestination(
            icon: Icon(Icons.terminal_outlined),
            selectedIcon: Icon(Icons.terminal),
            label: 'Console',
          ),
          NavigationDestination(
            icon: Icon(Icons.tune_outlined),
            selectedIcon: Icon(Icons.tune),
            label: 'Controls',
          ),
          NavigationDestination(
            icon: Icon(Icons.more_horiz),
            label: 'Settings',
          ),
        ],
      ),
    );
  }

  int get _mobileIndex => switch (_destination) {
        _WorkspaceDestination.overview => 0,
        _WorkspaceDestination.console => 1,
        _WorkspaceDestination.controls => 2,
        _ => 3,
      };
}

class _WorkspaceSidebar extends StatelessWidget {
  final Model model;
  final _WorkspaceDestination destination;
  final ValueChanged<_WorkspaceDestination> onDestination;
  final Future<void> Function(String) onSelectServer;
  final Future<void> Function() onAddServer;

  const _WorkspaceSidebar({
    required this.model,
    required this.destination,
    required this.onDestination,
    required this.onSelectServer,
    required this.onAddServer,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    return ColoredBox(
      // The rail reads as chrome by sitting away from the page in tone, which
      // means deeper in light mode and lighter in dark: the page is the lightest
      // surface in one and the darkest in the other.
      color: theme.brightness == Brightness.light
          ? scheme.surfaceContainerHigh
          : scheme.surfaceContainerLow,
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(12, 14, 12, 12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _AppTitle(
                onTap: () => onDestination(_WorkspaceDestination.preferences),
              ),
              ServerSwitcher(
                model: model,
                onSelect: onSelectServer,
                onAdd: onAddServer,
              ),
              const SizedBox(height: 16),
              const _SectionLabel(label: 'Server'),
              _NavigationTile(
                destination: _WorkspaceDestination.overview,
                selected: destination == _WorkspaceDestination.overview,
                onTap: onDestination,
              ),
              _NavigationTile(
                destination: _WorkspaceDestination.console,
                selected: destination == _WorkspaceDestination.console,
                onTap: onDestination,
              ),
              _NavigationTile(
                destination: _WorkspaceDestination.controls,
                selected: destination == _WorkspaceDestination.controls,
                onTap: onDestination,
              ),
              _NavigationTile(
                destination: _WorkspaceDestination.serverEditor,
                selected: destination == _WorkspaceDestination.serverEditor,
                onTap: onDestination,
              ),
              const Spacer(),
              const _SectionLabel(label: 'Application'),
              _NavigationTile(
                destination: _WorkspaceDestination.servers,
                selected: destination == _WorkspaceDestination.servers,
                onTap: onDestination,
              ),
              _NavigationTile(
                destination: _WorkspaceDestination.dataSync,
                selected: destination == _WorkspaceDestination.dataSync,
                onTap: onDestination,
              ),
              _NavigationTile(
                destination: _WorkspaceDestination.preferences,
                selected: destination == _WorkspaceDestination.preferences,
                onTap: onDestination,
              ),
              _ActionTile(
                icon: Icons.help_outline,
                label: 'Docs',
                onTap: () => UrlUtils.openDocumentation(),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _WorkspaceHeader extends StatelessWidget {
  final _WorkspaceDestination destination;
  final Model model;
  final ConnectionController connection;

  const _WorkspaceHeader({
    required this.destination,
    required this.model,
    required this.connection,
  });

  String get _subtitle => switch (destination) {
        _WorkspaceDestination.overview ||
        _WorkspaceDestination.console ||
        _WorkspaceDestination.controls ||
        _WorkspaceDestination.serverEditor =>
          model.ip.isEmpty
              ? model.selectedServer.edition.label
              : '${model.selectedServer.edition.label} · ${model.ip}:${model.port}',
        _WorkspaceDestination.servers => 'Manage saved server profiles',
        _WorkspaceDestination.dataSync =>
          'Back up and transfer application data',
        _WorkspaceDestination.preferences => 'Application-wide settings',
        _WorkspaceDestination.more => 'Application tools and settings',
      };

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      bottom: false,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 10),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    destination.label,
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                  Text(
                    _subtitle,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                ],
              ),
            ),
            _StatusLabel(status: connection.status),
            const SizedBox(width: 8),
            _ConnectionAction(model: model, connection: connection),
          ],
        ),
      ),
    );
  }
}

class _NavigationTile extends StatelessWidget {
  final _WorkspaceDestination destination;
  final bool selected;
  final ValueChanged<_WorkspaceDestination> onTap;

  const _NavigationTile({
    required this.destination,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 3),
      child: Material(
        color: Colors.transparent,
        child: ListTile(
          dense: true,
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
          selected: selected,
          selectedTileColor: Theme.of(context).colorScheme.secondaryContainer,
          leading: Icon(destination.icon, size: 21),
          title: Text(destination.label),
          onTap: () => onTap(destination),
        ),
      ),
    );
  }
}

/// The logo, the app name and a faint version, as one target that opens
/// Preferences, where the full version and build stamp live.
class _AppTitle extends StatefulWidget {
  final VoidCallback onTap;

  const _AppTitle({required this.onTap});

  @override
  State<_AppTitle> createState() => _AppTitleState();
}

class _AppTitleState extends State<_AppTitle> {
  String _version = '';
  String _tooltip = 'Preferences';

  @override
  void initState() {
    super.initState();
    _loadVersion();
  }

  Future<void> _loadVersion() async {
    final info = await PackageInfo.fromPlatform();
    if (!mounted) return;
    setState(() {
      _version = info.version;
      _tooltip = 'Admincraft ${info.version}+${info.buildNumber}'
          '${BuildInfo.isKnown ? '\n${BuildInfo.description}' : ''}';
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: Tooltip(
        message: _tooltip,
        child: InkWell(
          key: const ValueKey('app-title'),
          onTap: widget.onTap,
          borderRadius: BorderRadius.circular(10),
          child: Padding(
            padding: const EdgeInsets.fromLTRB(6, 4, 6, 4),
            child: Row(
              children: [
                const ThemeLogo(),
                const SizedBox(width: 10),
                Flexible(
                  child: Text(
                    'Admincraft',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: theme.textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.w700,
                      letterSpacing: -0.4,
                    ),
                  ),
                ),
                if (_version.isNotEmpty) ...[
                  const SizedBox(width: 6),
                  // Deliberately faint: useful when reporting a problem,
                  // noise the rest of the time.
                  Padding(
                    padding: const EdgeInsets.only(top: 6),
                    child: Text(
                      _version,
                      style: theme.textTheme.labelSmall?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant
                            .withValues(alpha: 0.45),
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _SectionLabel extends StatelessWidget {
  final String label;

  const _SectionLabel({required this.label});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(10, 6, 10, 5),
      child: Text(
        label.toUpperCase(),
        style: Theme.of(context).textTheme.labelSmall?.copyWith(
              color: Theme.of(context).colorScheme.onSurfaceVariant,
            ),
      ),
    );
  }
}

class _ActionTile extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;

  const _ActionTile({
    required this.icon,
    required this.label,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 3),
      child: Material(
        color: Colors.transparent,
        child: ListTile(
          dense: true,
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
          leading: Icon(icon, size: 21),
          title: Text(label),
          trailing: const Icon(Icons.open_in_new, size: 16),
          onTap: onTap,
        ),
      ),
    );
  }
}

class _StatusLabel extends StatelessWidget {
  final ConnectionStatus status;

  const _StatusLabel({required this.status});

  @override
  Widget build(BuildContext context) {
    final (label, color) = switch (status) {
      ConnectionStatus.connected => ('Connected', Colors.green),
      ConnectionStatus.connecting => ('Connecting', Colors.orange),
      ConnectionStatus.disconnected => ('Disconnected', Colors.red),
    };
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 8,
          height: 8,
          decoration: BoxDecoration(color: color, shape: BoxShape.circle),
        ),
        const SizedBox(width: 6),
        Text(label, style: Theme.of(context).textTheme.labelLarge),
      ],
    );
  }
}

class _ConnectionAction extends StatelessWidget {
  final Model model;
  final ConnectionController connection;

  const _ConnectionAction({required this.model, required this.connection});

  @override
  Widget build(BuildContext context) {
    final connected = connection.status == ConnectionStatus.connected;
    final connecting = connection.status == ConnectionStatus.connecting;
    // An incomplete profile cannot connect, so the control is disabled and says
    // why, rather than looking available and failing when pressed.
    final ready = model.selectedServer.isComplete;

    return IconButton.filledTonal(
      tooltip: !ready
          ? 'Finish setting up this server first'
          : (connected ? 'Disconnect' : 'Connect'),
      onPressed: connecting || (!ready && !connected)
          ? null
          : () => connection.toggleConnection(model),
      icon: connecting
          ? const SizedBox(
              width: 20,
              height: 20,
              child: CircularProgressIndicator(strokeWidth: 2),
            )
          : Icon(connected ? Icons.stop_rounded : Icons.play_arrow_rounded),
    );
  }
}

class _KeepAlivePage extends StatefulWidget {
  final Widget child;

  const _KeepAlivePage({required this.child});

  @override
  State<_KeepAlivePage> createState() => _KeepAlivePageState();
}

class _KeepAlivePageState extends State<_KeepAlivePage>
    with AutomaticKeepAliveClientMixin {
  @override
  bool get wantKeepAlive => true;

  @override
  Widget build(BuildContext context) {
    super.build(context);
    return widget.child;
  }
}
