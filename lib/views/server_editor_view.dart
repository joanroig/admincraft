import 'dart:convert';
import 'dart:io';

import 'package:admincraft/models/connection_security.dart';
import 'package:admincraft/models/minecraft_edition.dart';
import 'package:admincraft/models/model.dart';
import 'package:admincraft/services/websocket_connector.dart';
import 'package:admincraft/utils/dialog_utils.dart';
import 'package:admincraft/utils/toast_utils.dart';
import 'package:admincraft/utils/url_utils.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

class ServerEditorView extends StatefulWidget {
  final Future<void> Function() onSaved;
  final Future<void> Function() onDeleted;
  final VoidCallback onBack;

  const ServerEditorView({
    super.key,
    required this.onSaved,
    required this.onDeleted,
    required this.onBack,
  });

  @override
  State<ServerEditorView> createState() => _ServerEditorViewState();
}

class _ServerEditorViewState extends State<ServerEditorView> {
  final _formKey = GlobalKey<FormState>();
  final _aliasController = TextEditingController();
  final _hostController = TextEditingController();
  final _portController = TextEditingController();
  final _secretController = TextEditingController();
  final _certificateController = TextEditingController();

  late Model _model;
  late ConnectionSecurity _security;
  late MinecraftEdition _edition;
  String _certificateContent = '';
  bool _secretVisible = false;
  bool _saving = false;

  List<ConnectionSecurity> get _securityOptions => ConnectionSecurity.values
      .where((value) => supportsCustomCertificate || !value.requiresCertificate)
      .toList();

  @override
  void initState() {
    super.initState();
    _model = context.read<Model>();
    final server = _model.selectedServer;
    _aliasController.text = server.alias;
    _hostController.text = server.ip;
    _portController.text = server.port.toString();
    _secretController.text = server.secretKey;
    _certificateContent = server.certificate;
    _certificateController.text = server.certificate.isEmpty
        ? 'No certificate loaded'
        : 'Certificate loaded';
    _security = _securityOptions.contains(server.security)
        ? server.security
        : ConnectionSecurity.trustedCertificate;
    _edition = server.edition;
  }

  String get _connectionPreview {
    final scheme = _security.usesTls ? 'wss' : 'ws';
    final host = _hostController.text.trim().isEmpty
        ? '<host>'
        : _hostController.text.trim();
    final port = _portController.text.trim().isEmpty
        ? '<port>'
        : _portController.text.trim();
    return '$scheme://$host:$port';
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
  }

  Future<void> _save() async {
    if (!(_formKey.currentState?.validate() ?? false)) return;
    if (_security.requiresCertificate && _certificateContent.isEmpty) {
      ToastUtils.showToastError(
          'Load a server certificate or choose another security mode.');
      return;
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
      );
      await widget.onSaved();
      ToastUtils.showToastSuccess('Server saved.');
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
                          Text('Edit server',
                              style:
                                  Theme.of(context).textTheme.headlineMedium),
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
                          'getting-started/first-server/'),
                      icon: const Icon(Icons.help_outline),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                _SectionCard(
                  title: 'General',
                  subtitle: 'Name and Minecraft edition.',
                  child: LayoutBuilder(
                    builder: (context, constraints) {
                      final wide = constraints.maxWidth >= 580;
                      final alias = TextFormField(
                        controller: _aliasController,
                        decoration: const InputDecoration(labelText: 'Alias'),
                        validator: (value) =>
                            value == null || value.trim().isEmpty
                                ? 'Enter a name for this server.'
                                : null,
                      );
                      final edition = DropdownButtonFormField<MinecraftEdition>(
                        initialValue: _edition,
                        isExpanded: true,
                        decoration: const InputDecoration(
                            labelText: 'Minecraft edition'),
                        items: MinecraftEdition.values
                            .map((value) => DropdownMenuItem(
                                  value: value,
                                  child: Text(value.label),
                                ))
                            .toList(),
                        onChanged: (value) {
                          if (value != null) setState(() => _edition = value);
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
                          : Column(children: [
                              alias,
                              const SizedBox(height: 12),
                              edition
                            ]);
                    },
                  ),
                ),
                const SizedBox(height: 14),
                _SectionCard(
                  title: 'Connection',
                  subtitle: 'How Admincraft reaches the WebSocket bridge.',
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      LayoutBuilder(
                        builder: (context, constraints) {
                          final wide = constraints.maxWidth >= 580;
                          final host = TextFormField(
                            controller: _hostController,
                            decoration:
                                const InputDecoration(labelText: 'Host or IP'),
                            onChanged: (_) => setState(() {}),
                            validator: (value) =>
                                value == null || value.trim().isEmpty
                                    ? 'Enter the server host.'
                                    : null,
                          );
                          final port = TextFormField(
                            controller: _portController,
                            decoration:
                                const InputDecoration(labelText: 'Port'),
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
                              ? Row(children: [
                                  Expanded(flex: 3, child: host),
                                  const SizedBox(width: 12),
                                  Expanded(child: port),
                                ])
                              : Column(children: [
                                  host,
                                  const SizedBox(height: 12),
                                  port
                                ]);
                        },
                      ),
                      const SizedBox(height: 12),
                      TextFormField(
                        controller: _secretController,
                        obscureText: !_secretVisible,
                        enableSuggestions: false,
                        autocorrect: false,
                        decoration: InputDecoration(
                          labelText: 'Secret key',
                          suffixIcon: IconButton(
                            tooltip: _secretVisible ? 'Hide key' : 'Show key',
                            icon: Icon(_secretVisible
                                ? Icons.visibility_off
                                : Icons.visibility),
                            onPressed: () => setState(
                                () => _secretVisible = !_secretVisible),
                          ),
                        ),
                        validator: (value) => value == null || value.isEmpty
                            ? 'Enter the WebSocket secret key.'
                            : null,
                      ),
                      const SizedBox(height: 12),
                      DropdownButtonFormField<ConnectionSecurity>(
                        initialValue: _security,
                        isExpanded: true,
                        decoration: const InputDecoration(
                            labelText: 'Connection security'),
                        items: _securityOptions
                            .map((value) => DropdownMenuItem(
                                  value: value,
                                  child: Text(value.label),
                                ))
                            .toList(),
                        onChanged: (value) {
                          if (value != null) setState(() => _security = value);
                        },
                      ),
                      Padding(
                        padding: const EdgeInsets.fromLTRB(12, 8, 12, 0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(_security.description,
                                style: Theme.of(context).textTheme.bodySmall),
                            const SizedBox(height: 4),
                            Text(
                              _connectionPreview,
                              style: Theme.of(context)
                                  .textTheme
                                  .labelLarge
                                  ?.copyWith(
                                    color: _security.usesTls
                                        ? Theme.of(context).colorScheme.primary
                                        : Theme.of(context).colorScheme.error,
                                  ),
                            ),
                            TextButton.icon(
                              onPressed: () => UrlUtils.openDocumentation(
                                  'guides/connection-security/'),
                              icon: const Icon(Icons.menu_book_outlined,
                                  size: 18),
                              label: const Text('Connection security guide'),
                            ),
                          ],
                        ),
                      ),
                      if (_security.requiresCertificate) ...[
                        const SizedBox(height: 8),
                        TextField(
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
                                    onPressed: () => setState(() {
                                      _certificateContent = '';
                                      _certificateController.text =
                                          'No certificate loaded';
                                    }),
                                    icon: const Icon(Icons.clear),
                                  ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ],
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
                              Text('Danger zone',
                                  style:
                                      Theme.of(context).textTheme.titleMedium),
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
              ],
            ),
          ),
        ),
      ),
    );
  }

  @override
  void dispose() {
    _aliasController.dispose();
    _hostController.dispose();
    _portController.dispose();
    _secretController.dispose();
    _certificateController.dispose();
    super.dispose();
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
