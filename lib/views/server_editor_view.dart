import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:ui' as ui;

import 'package:admincraft/models/connection_security.dart';
import 'package:admincraft/models/minecraft_edition.dart';
import 'package:admincraft/models/model.dart';
import 'package:admincraft/services/rcon_client.dart';
import 'package:admincraft/services/websocket_connector.dart';
import 'package:admincraft/utils/dialog_utils.dart';
import 'package:admincraft/utils/host_utils.dart';
import 'package:admincraft/utils/toast_utils.dart';
import 'package:admincraft/utils/url_utils.dart';
import 'package:admincraft/views/widgets/server_icon.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

class ServerEditorController {
  Future<bool> Function()? _save;
  VoidCallback? _discard;

  Future<bool> save() => _save?.call() ?? Future.value(false);
  void discard() => _discard?.call();

  void _attach(Future<bool> Function() save, VoidCallback discard) {
    _save = save;
    _discard = discard;
  }

  void _detach() {
    _save = null;
    _discard = null;
  }
}

class ServerEditorView extends StatefulWidget {
  final ServerEditorController controller;
  final Future<void> Function() onSaved;
  final Future<void> Function() onDeleted;
  final VoidCallback onBack;
  final ValueChanged<bool>? onDirtyChanged;

  const ServerEditorView({
    super.key,
    required this.controller,
    required this.onSaved,
    required this.onDeleted,
    required this.onBack,
    this.onDirtyChanged,
  });

  @override
  State<ServerEditorView> createState() => _ServerEditorViewState();
}

class _ServerEditorViewState extends State<ServerEditorView> {
  GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  final _aliasController = TextEditingController();
  final _hostController = TextEditingController();
  final _portController = TextEditingController();
  final _secretController = TextEditingController();
  final _certificateController = TextEditingController();

  late Model _model;
  late ConnectionSecurity _security;
  late MinecraftEdition _edition;
  String _certificateContent = '';
  String _iconAsset = serverIconAssets.first;
  String _customIconBase64 = '';
  bool _secretVisible = false;
  bool _saving = false;
  bool _showValidationErrors = false;
  bool _loadingServer = false;

  /// Options depend on the edition and the platform, so the list is rebuilt
  /// rather than fixed: Bedrock has no RCON at all, and a browser cannot open
  /// the raw socket RCON needs.
  List<ConnectionSecurity> get _securityOptions =>
      ConnectionSecurity.values.where((value) {
        if (value.requiresCertificate && !supportsCustomCertificate) {
          return false;
        }
        if (value.isDirectRcon) {
          return _edition == MinecraftEdition.java && supportsDirectRcon;
        }
        return true;
      }).toList();

  @override
  void initState() {
    super.initState();
    _model = context.read<Model>();
    _loadSelectedServer();
    for (final controller in [
      _aliasController,
      _hostController,
      _portController,
      _secretController,
    ]) {
      controller.addListener(_reportDirty);
    }
    widget.controller._attach(_save, _discardChanges);
  }

  void _loadSelectedServer() {
    final server = _model.selectedServer;
    _loadingServer = true;
    _aliasController.text = server.alias;
    _hostController.text = server.ip;
    _portController.text = server.port.toString();
    _secretController.text = server.secretKey;
    _certificateContent = server.certificate;
    _iconAsset = server.iconAsset;
    _customIconBase64 = server.customIconBase64;
    _certificateController.text = server.certificate.isEmpty
        ? 'No certificate loaded'
        : 'Certificate loaded';
    // Edition first: _securityOptions reads it to decide whether direct RCON is
    // offered, so setting _security before it would read an uninitialised field.
    _edition = server.edition;
    _security = _securityOptions.contains(server.security)
        ? server.security
        : ConnectionSecurity.trustedCertificate;
    _loadingServer = false;
  }

  void _discardChanges() {
    if (!mounted) return;
    setState(() {
      _formKey = GlobalKey<FormState>();
      _showValidationErrors = false;
      _loadSelectedServer();
    });
    widget.onDirtyChanged?.call(false);
  }

  @override
  void didUpdateWidget(covariant ServerEditorView oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.controller == widget.controller) return;
    oldWidget.controller._detach();
    widget.controller._attach(_save, _discardChanges);
  }

  @override
  void dispose() {
    widget.controller._detach();
    for (final controller in [
      _aliasController,
      _hostController,
      _portController,
      _secretController,
      _certificateController,
    ]) {
      controller.dispose();
    }
    super.dispose();
  }

  void _reportDirty() {
    if (_loadingServer) return;
    final original = _model.selectedServer;
    final dirty =
        _aliasController.text != original.alias ||
        _hostController.text != original.ip ||
        _portController.text != original.port.toString() ||
        _secretController.text != original.secretKey ||
        _certificateContent != original.certificate ||
        _security != original.security ||
        _edition != original.edition ||
        _iconAsset != original.iconAsset ||
        _customIconBase64 != original.customIconBase64;
    widget.onDirtyChanged?.call(dirty);
  }

  String get _connectionPreview {
    // Parsed rather than shown raw, so someone pasting a URL sees the address
    // that will actually be used while they are still looking at the field.
    final parsed = HostInput.parse(_hostController.text);
    final host = parsed.host;
    final port =
        (parsed.port ?? int.tryParse(_portController.text.trim()))
            ?.toString() ??
        '';
    final shownHost = host.isEmpty ? '<host>' : host;
    final shownPort = port.isEmpty ? '<port>' : port;

    // RCON is not a URL scheme, so labelling it ws:// would be a lie.
    if (_security.isDirectRcon) {
      return 'rcon://$shownHost:$shownPort  (not encrypted)';
    }

    final scheme = _security.usesTls ? 'wss' : 'ws';
    final suffix = _security.usesTls ? '' : '  (not encrypted)';
    return '$scheme://$shownHost:$shownPort$suffix';
  }

  Future<void> _pickCertificate() async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: const ['crt'],
      withData: kIsWeb,
    );
    if (result == null) return;

    final file = result.files.single;
    final content = kIsWeb
        ? utf8.decode(file.bytes!)
        : await File(file.path!).readAsString();
    if (!mounted) return;
    setState(() {
      _certificateContent = content;
      _certificateController.text = 'Certificate loaded';
    });
    _reportDirty();
  }

  Future<void> _pickServerIcon() async {
    final selection = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Server logo'),
        content: SizedBox(
          width: 360,
          child: GridView.count(
            shrinkWrap: true,
            crossAxisCount: 5,
            mainAxisSpacing: 8,
            crossAxisSpacing: 8,
            children: [
              for (final asset in serverIconAssets)
                InkWell(
                  borderRadius: BorderRadius.circular(8),
                  onTap: () => Navigator.pop(context, asset),
                  child: Padding(
                    padding: const EdgeInsets.all(8),
                    child: Image.asset(
                      asset,
                      filterQuality: FilterQuality.none,
                      isAntiAlias: false,
                    ),
                  ),
                ),
              InkWell(
                borderRadius: BorderRadius.circular(8),
                onTap: () => Navigator.pop(context, '__custom__'),
                child: const Tooltip(
                  message: 'Upload a 16 x 16 PNG',
                  child: Icon(Icons.add_photo_alternate_outlined),
                ),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
        ],
      ),
    );
    if (selection == null || !mounted) return;
    if (selection != '__custom__') {
      setState(() {
        _iconAsset = selection;
        _customIconBase64 = '';
      });
      _reportDirty();
      return;
    }

    final result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: const ['png'],
      withData: true,
    );
    final bytes = result?.files.single.bytes;
    if (bytes == null || !mounted) return;
    try {
      final codec = await ui.instantiateImageCodec(bytes);
      final frame = await codec.getNextFrame();
      final valid = frame.image.width == 16 && frame.image.height == 16;
      frame.image.dispose();
      codec.dispose();
      if (!valid) {
        ToastUtils.showToastError(
          'Choose a PNG that is exactly 16 x 16 pixels.',
        );
        return;
      }
    } catch (_) {
      ToastUtils.showToastError('That file is not a readable PNG image.');
      return;
    }
    if (!mounted) return;
    setState(() {
      _iconAsset = '';
      _customIconBase64 = base64Encode(bytes);
    });
    _reportDirty();
  }

  /// Reduces a pasted URL to the host, and takes the port with it.
  ///
  /// Every guide to Tailscale, Funnel or a reverse proxy hands out a URL, so
  /// that is what gets pasted. `https://host` used to be stored verbatim and
  /// built into `wss://https://host`, which fails with nothing on screen to
  /// explain why.
  void _normaliseHost() {
    final parsed = HostInput.parse(_hostController.text);
    if (!parsed.wasCleaned) return;

    setState(() {
      _hostController.text = parsed.host;
      if (parsed.port != null) _portController.text = parsed.port.toString();
    });

    ToastUtils.showToastSuccess(
      'Address read as ${parsed.host}'
      '${parsed.port != null ? ', port ${parsed.port}' : ''}.',
    );
  }

  Future<bool> _save() async {
    _normaliseHost();
    final valid = _formKey.currentState?.validate() ?? false;
    if (!valid) {
      if (mounted) setState(() => _showValidationErrors = true);
      ToastUtils.showToastError(
        'Complete the highlighted server fields before saving.',
      );
      return false;
    }

    setState(() => _saving = true);
    try {
      await _model.setConnectionDetails(
        alias: _aliasController.text.trim(),
        ip: _hostController.text.trim(),
        port: int.parse(_portController.text),
        secretKey: _secretController.text,
        certificate: _certificateContent,
        connectionSecurity: _security,
        minecraftEdition: _edition,
        iconAsset: _iconAsset,
        customIconBase64: _customIconBase64,
      );
      widget.onDirtyChanged?.call(false);
      // The profile is safely persisted at this point. Reconnecting and
      // scheduling Drive sync may take time, and must not hold a navigation
      // guard open over a completed save.
      unawaited(widget.onSaved());
      ToastUtils.showToastSuccess('Server saved.');
      return true;
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  Future<void> _delete() async {
    final server = _model.selectedServer;
    final confirmed = await DialogUtils.confirmAction(
      context,
      title: 'Delete ${server.alias}?',
      message:
          'This removes the profile and its secret key from this device. It does not stop the Minecraft server.',
      confirmLabel: 'Delete',
    );
    if (!confirmed) return;
    widget.onDirtyChanged?.call(false);
    await _model.deleteServer(server.id);
    await widget.onDeleted();
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 820),
          child: Form(
            key: _formKey,
            autovalidateMode: _showValidationErrors
                ? AutovalidateMode.always
                : AutovalidateMode.disabled,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Row(
                  children: [
                    if (MediaQuery.sizeOf(context).width >= 820) ...[
                      IconButton(
                        tooltip: 'Back to Servers',
                        onPressed: widget.onBack,
                        icon: const Icon(Icons.arrow_back),
                      ),
                      const SizedBox(width: 4),
                    ],
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Edit server',
                            style: Theme.of(context).textTheme.headlineMedium,
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'Connection details only affect ${_model.alias}.',
                            style: Theme.of(context).textTheme.bodyMedium,
                          ),
                        ],
                      ),
                    ),
                    IconButton(
                      tooltip: 'Server setup guide',
                      onPressed: () => UrlUtils.openDocumentation(
                        'getting-started/first-server/',
                      ),
                      icon: const Icon(Icons.help_outline),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                _SectionCard(
                  title: 'General',
                  subtitle: 'Name, logo and Minecraft edition.',
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: Theme.of(
                                context,
                              ).colorScheme.surfaceContainerHighest,
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: ServerIcon(
                              server: _model.selectedServer.copyWith(
                                iconAsset: _iconAsset,
                                customIconBase64: _customIconBase64,
                              ),
                              size: 32,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Text(
                              'A 16 px logo identifies this profile and is included in encrypted backups and Drive sync.',
                              style: Theme.of(context).textTheme.bodySmall,
                            ),
                          ),
                          TextButton.icon(
                            onPressed: _pickServerIcon,
                            icon: const Icon(Icons.image_outlined),
                            label: const Text('Choose'),
                          ),
                        ],
                      ),
                      const SizedBox(height: 14),
                      LayoutBuilder(
                        builder: (context, constraints) {
                          final wide = constraints.maxWidth >= 580;
                          final alias = TextFormField(
                            controller: _aliasController,
                            decoration: const InputDecoration(
                              labelText: 'Alias',
                            ),
                            validator: (value) =>
                                value == null || value.trim().isEmpty
                                ? 'Enter a name for this server.'
                                : null,
                          );
                          final edition =
                              DropdownButtonFormField<MinecraftEdition>(
                                initialValue: _edition,
                                isExpanded: true,
                                decoration: InputDecoration(
                                  labelText: 'Minecraft edition',
                                  helperText: _edition.connectivityHint,
                                  helperMaxLines: 2,
                                ),
                                items: MinecraftEdition.values
                                    .map(
                                      (value) => DropdownMenuItem(
                                        value: value,
                                        child: Text(value.label),
                                      ),
                                    )
                                    .toList(),
                                onChanged: (value) {
                                  if (value == null) return;
                                  setState(() {
                                    _edition = value;
                                    if (!_securityOptions.contains(_security)) {
                                      _security =
                                          ConnectionSecurity.privateNetwork;
                                      _portController.text = _security
                                          .suggestedPort
                                          .toString();
                                    }
                                  });
                                  _reportDirty();
                                },
                              );
                          return wide
                              ? Row(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Expanded(child: alias),
                                    const SizedBox(width: 12),
                                    Expanded(child: edition),
                                  ],
                                )
                              : Column(
                                  children: [
                                    alias,
                                    const SizedBox(height: 12),
                                    edition,
                                  ],
                                );
                        },
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 14),
                _SectionCard(
                  title: 'Connection',
                  subtitle: _security.fieldsDescribe,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      DropdownButtonFormField<ConnectionSecurity>(
                        initialValue: _security,
                        isExpanded: true,
                        decoration: const InputDecoration(
                          labelText: 'Connection type',
                        ),
                        items: _securityOptions
                            .map(
                              (value) => DropdownMenuItem(
                                value: value,
                                child: Text(value.typeLabel),
                              ),
                            )
                            .toList(),
                        onChanged: (value) {
                          if (value == null) return;
                          setState(() {
                            final previous = _security;
                            _security = value;
                            final current = int.tryParse(_portController.text);
                            final wasADefault =
                                current == null ||
                                current == previous.suggestedPort;
                            if (wasADefault) {
                              _portController.text = value.suggestedPort
                                  .toString();
                            }
                          });
                          _reportDirty();
                        },
                      ),
                      Padding(
                        padding: const EdgeInsets.fromLTRB(12, 8, 12, 0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              _security.description,
                              style: Theme.of(context).textTheme.bodySmall,
                            ),
                            const SizedBox(height: 4),
                            Text(
                              _connectionPreview,
                              style: Theme.of(context).textTheme.labelLarge
                                  ?.copyWith(
                                    color: _security.usesTls
                                        ? Theme.of(context).colorScheme.primary
                                        : Theme.of(context).colorScheme.error,
                                  ),
                            ),
                            TextButton.icon(
                              onPressed: () => UrlUtils.openDocumentation(
                                'guides/connection-fields/',
                              ),
                              icon: const Icon(
                                Icons.menu_book_outlined,
                                size: 18,
                              ),
                              label: const Text('What do these fields mean?'),
                            ),
                          ],
                        ),
                      ),
                      LayoutBuilder(
                        builder: (context, constraints) {
                          final wide = constraints.maxWidth >= 580;
                          final host = TextFormField(
                            controller: _hostController,
                            decoration: InputDecoration(
                              labelText: _security.hostLabel,
                              helperText: _security.hostHint,
                            ),
                            onChanged: (_) => setState(() {}),
                            validator: (value) =>
                                value == null || value.trim().isEmpty
                                ? 'Enter the server host.'
                                : null,
                          );
                          final port = TextFormField(
                            controller: _portController,
                            decoration: InputDecoration(
                              labelText: _security.portLabel,
                              helperText: _security.portHint,
                              helperMaxLines: 2,
                            ),
                            keyboardType: TextInputType.number,
                            onChanged: (_) => setState(() {}),
                            validator: (value) {
                              final port = int.tryParse(value ?? '');
                              return port == null || port < 1 || port > 65535
                                  ? 'Enter a port from 1 to 65535.'
                                  : null;
                            },
                          );
                          return wide
                              ? Row(
                                  children: [
                                    Expanded(flex: 3, child: host),
                                    const SizedBox(width: 12),
                                    Expanded(child: port),
                                  ],
                                )
                              : Column(
                                  children: [
                                    host,
                                    const SizedBox(height: 12),
                                    port,
                                  ],
                                );
                        },
                      ),
                      const SizedBox(height: 12),
                      TextFormField(
                        controller: _secretController,
                        obscureText: !_secretVisible,
                        enableSuggestions: false,
                        autocorrect: false,
                        decoration: InputDecoration(
                          labelText: _security.secretLabel,
                          helperText: _security.secretHint,
                          helperMaxLines: 2,
                          suffixIcon: IconButton(
                            tooltip:
                                '${_secretVisible ? 'Hide' : 'Show'} ${_security.secretNoun}',
                            icon: Icon(
                              _secretVisible
                                  ? Icons.visibility_off
                                  : Icons.visibility,
                            ),
                            onPressed: () => setState(
                              () => _secretVisible = !_secretVisible,
                            ),
                          ),
                        ),
                        validator: (value) => value == null || value.isEmpty
                            ? _security.secretMissingMessage
                            : null,
                      ),
                      const SizedBox(height: 12),
                      if (_security.requiresCertificate) ...[
                        const SizedBox(height: 8),
                        TextFormField(
                          controller: _certificateController,
                          readOnly: true,
                          decoration: InputDecoration(
                            labelText: 'Server certificate',
                            suffixIcon: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                IconButton(
                                  tooltip: 'Load certificate',
                                  onPressed: _pickCertificate,
                                  icon: const Icon(Icons.folder_open),
                                ),
                                if (_certificateContent.isNotEmpty)
                                  IconButton(
                                    tooltip: 'Remove certificate',
                                    onPressed: () {
                                      setState(() {
                                        _certificateContent = '';
                                        _certificateController.text =
                                            'No certificate loaded';
                                      });
                                      _reportDirty();
                                    },
                                    icon: const Icon(Icons.clear),
                                  ),
                              ],
                            ),
                          ),
                          validator: (_) =>
                              _security.requiresCertificate &&
                                  _certificateContent.isEmpty
                              ? 'Load a server certificate or choose another security mode.'
                              : null,
                        ),
                      ],
                    ],
                  ),
                ),
                const SizedBox(height: 16),
                Align(
                  alignment: Alignment.centerRight,
                  child: FilledButton.icon(
                    onPressed: _saving ? null : _save,
                    icon: _saving
                        ? const SizedBox(
                            width: 18,
                            height: 18,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : const Icon(Icons.save_outlined),
                    label: Text(_saving ? 'Saving…' : 'Save changes'),
                  ),
                ),
                if (_model.servers.length > 1) ...[
                  const SizedBox(height: 14),
                  Card(
                    color: Theme.of(context).colorScheme.errorContainer,
                    child: Padding(
                      padding: const EdgeInsets.all(18),
                      child: LayoutBuilder(
                        builder: (context, constraints) {
                          final details = Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Danger zone',
                                style: Theme.of(context).textTheme.titleMedium,
                              ),
                              const SizedBox(height: 4),
                              const Text(
                                'Remove this profile and its credentials from this device.',
                              ),
                            ],
                          );
                          final deleteButton = OutlinedButton.icon(
                            onPressed: _delete,
                            icon: const Icon(Icons.delete_outline),
                            label: const Text('Delete server'),
                          );

                          if (constraints.maxWidth >= 560) {
                            return Row(
                              children: [
                                Expanded(child: details),
                                const SizedBox(width: 16),
                                deleteButton,
                              ],
                            );
                          }

                          return Column(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              details,
                              const SizedBox(height: 14),
                              deleteButton,
                            ],
                          );
                        },
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

class _SectionCard extends StatelessWidget {
  final String title;
  final String subtitle;
  final Widget child;

  const _SectionCard({
    required this.title,
    required this.subtitle,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(title, style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 3),
            Text(subtitle, style: Theme.of(context).textTheme.bodySmall),
            const SizedBox(height: 16),
            child,
          ],
        ),
      ),
    );
  }
}
