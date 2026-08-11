import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:admincraft/models/connection_security.dart';
import 'package:admincraft/models/minecraft_edition.dart';
import 'package:admincraft/models/model.dart';
import 'package:admincraft/services/theme_service.dart';
import 'package:admincraft/services/config_file.dart';
import 'package:admincraft/services/config_transfer.dart';
import 'package:admincraft/services/websocket_connector.dart';
import 'package:admincraft/utils/dialog_utils.dart';
import 'package:admincraft/utils/toast_utils.dart';
import 'package:admincraft/utils/url_utils.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:package_info_plus/package_info_plus.dart'; // Import for package info
import 'package:provider/provider.dart';

class SettingsTab extends StatefulWidget {
  final VoidCallback onSettingsSaved;

  const SettingsTab({super.key, required this.onSettingsSaved});

  @override
  State<SettingsTab> createState() => _SettingsTabState();
}

class _SettingsTabState extends State<SettingsTab> {
  final TextEditingController _aliasController = TextEditingController();
  final TextEditingController _ipController = TextEditingController();
  final TextEditingController _portController = TextEditingController();
  final TextEditingController _secretKeyController = TextEditingController();
  final TextEditingController _certificateController = TextEditingController();
  final TextEditingController _maxOutLinesController = TextEditingController();
  ThemeMode _selectedThemeMode = ThemeMode.system;
  final TextEditingController _fontSizeController = TextEditingController();
  String _selectedFont = '';
  double _currentFontSize = 16.0;
  late Model _model;
  String _version = '';
  String _buildNumber = '';
  bool _isSecretVisible = false;
  String _certificateContent = '';
  ConnectionSecurity _selectedSecurity = ConnectionSecurity.privateNetwork;
  MinecraftEdition _selectedEdition = MinecraftEdition.bedrock;

  @override
  void initState() {
    super.initState();
    _model = Provider.of<Model>(context, listen: false);
    _selectedFont = _model.font;
    _currentFontSize = _model.fontSize;
    _loadSettings();
    _loadAppInfo(); // Load app version and build number
    _updateCertificateMessage(); // Update certificate message on init
  }

  Future<void> _loadSettings() async {
    _aliasController.text = _model.alias;
    _ipController.text = _model.ip;
    _portController.text = _model.port.toString();
    _secretKeyController.text = _model.secretKey;
    _certificateContent = _model.certificate;
    _selectedSecurity = _model.connectionSecurity;
    _selectedEdition = _model.minecraftEdition;
    // A setting saved on another platform can name a mode this one cannot
    // offer, which would leave the dropdown without a matching entry.
    if (!_securityOptions.contains(_selectedSecurity)) {
      _selectedSecurity = ConnectionSecurity.trustedCertificate;
    }
    _selectedThemeMode = _model.themeMode;
    _fontSizeController.text = _model.fontSize.toString();
    _maxOutLinesController.text = _model.maxOutLines.toString();
  }

  Future<void> _loadAppInfo() async {
    final packageInfo = await PackageInfo.fromPlatform();
    setState(() {
      _version = packageInfo.version;
      _buildNumber = packageInfo.buildNumber;
    });
  }

  void _updateCertificateMessage() {
    if (_certificateContent.isNotEmpty) {
      _certificateController.text = 'Certificate Loaded';
    } else {
      _certificateController.text = 'No Certificate Loaded';
    }
  }

  /// Pinning a certificate needs a trust store the app controls, which the
  /// browser does not expose, so that mode is hidden on web.
  List<ConnectionSecurity> get _securityOptions => ConnectionSecurity.values
      .where((security) =>
          supportsCustomCertificate || !security.requiresCertificate)
      .toList();

  /// Key derivation is deliberately slow, so the buttons are disabled while it
  /// runs rather than letting a second tap queue up behind the first.
  bool _busy = false;

  Future<void> _export({required bool toClipboard}) async {
    final passphrase = await DialogUtils.promptForPassphrase(
      context,
      title: 'Export servers',
      message:
          'Choose a passphrase. You will need the same one to import this on another device.',
      confirm: true,
    );
    if (passphrase == null || !mounted) return;

    setState(() => _busy = true);
    try {
      final blob = await ConfigTransfer.export(_model.servers, passphrase);

      if (toClipboard) {
        await Clipboard.setData(ClipboardData(text: blob));
        ToastUtils.showToastSuccess(
            'Config copied. Paste it on your other device.');
      } else {
        final path = await saveConfigFile(ConfigTransfer.fileName(), blob);
        if (path != null) ToastUtils.showToastSuccess('Saved to $path');
      }
    } catch (e) {
      ToastUtils.showToastError('Export failed: $e');
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _importFromClipboard() async {
    try {
      final data = await Clipboard.getData(Clipboard.kTextPlain);
      final blob = data?.text;
      if (blob == null || blob.trim().isEmpty) {
        ToastUtils.showToastError('The clipboard is empty.');
        return;
      }
      await _import(blob);
    } catch (e) {
      ToastUtils.showToastError('Could not read the clipboard: $e');
    }
  }

  Future<void> _importFromFile() async {
    try {
      final result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: const ['json'],
        // Needed on web, where there is no path to read from afterwards.
        withData: true,
      );
      if (result == null) return;

      final file = result.files.single;
      final blob = file.bytes != null
          ? utf8.decode(file.bytes!)
          : await File(file.path!).readAsString();

      await _import(blob);
    } catch (e) {
      ToastUtils.showToastError('Could not read the config file: $e');
    }
  }

  Future<void> _import(String blob) async {
    if (!mounted) return;
    final passphrase = await DialogUtils.promptForPassphrase(
      context,
      title: 'Import servers',
      message: 'Enter the passphrase this config was exported with.',
      confirm: false,
    );
    if (passphrase == null || !mounted) return;

    setState(() => _busy = true);
    try {
      final servers = await ConfigTransfer.import(blob, passphrase);
      if (servers.isEmpty) {
        throw const ConfigTransferException(
            'This config does not contain any servers.');
      }
      if (!mounted) return;

      final confirmed = await DialogUtils.confirmAction(
        context,
        title: 'Import ${servers.length} server(s)?',
        message:
            'Profiles with matching IDs will be updated. Your other saved servers will stay.',
        confirmLabel: 'Import',
      );
      if (!confirmed || !mounted) return;

      final selectedBefore = _model.selectedServer.toJson();
      final result = await _model.importServers(servers);
      ToastUtils.showToastSuccess(
        'Imported ${result.added} new and updated ${result.updated} server(s).',
      );
      if (mounted) {
        _loadSettings();
        if (!mapEquals(selectedBefore, _model.selectedServer.toJson())) {
          widget.onSettingsSaved();
        }
      }
    } on ConfigTransferException catch (e) {
      ToastUtils.showToastError(e.message);
    } catch (e) {
      ToastUtils.showToastError('Import failed: $e');
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _deleteServer() async {
    final server = _model.selectedServer;
    final confirmed = await DialogUtils.confirmAction(
      context,
      title: 'Delete Server',
      message:
          'Remove "${server.alias}" and its saved secret key from this device?',
      confirmLabel: 'Delete',
    );
    if (!confirmed) return;

    await _model.deleteServer(server.id);
    if (!mounted) return;
    widget.onSettingsSaved();
  }

  String _connectionPreview() {
    final scheme = _selectedSecurity.usesTls ? 'wss' : 'ws';
    final host =
        _ipController.text.trim().isEmpty ? '<ip>' : _ipController.text.trim();
    final port = _portController.text.trim().isEmpty
        ? '<port>'
        : _portController.text.trim();
    final suffix = _selectedSecurity.usesTls ? '' : '  (not encrypted)';
    return '$scheme://$host:$port$suffix';
  }

  Future<void> _pickCertificateFile() async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['crt'],
    );

    if (result != null) {
      if (kIsWeb) {
        final fileBytes = result.files.first.bytes;
        if (fileBytes == null) return;
        _certificateContent = utf8.decode(fileBytes);
      } else {
        _certificateContent =
            await File(result.files.single.path!).readAsString();
      }

      setState(() {
        _updateCertificateMessage(); // Update message after loading the certificate
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Server Settings Header
          Row(
            children: [
              Expanded(
                child: Text(
                  'Server Settings',
                  style: Theme.of(context).textTheme.headlineMedium,
                ),
              ),
              IconButton(
                icon: const Icon(Icons.help_outline),
                tooltip: 'Server setup guide',
                onPressed: () => UrlUtils.openDocumentation(
                  'getting-started/first-server/',
                ),
              ),
              // Hidden rather than disabled when only one server is left:
              // there always has to be a selected server to connect with.
              if (_model.servers.length > 1)
                IconButton(
                  icon: const Icon(Icons.delete_outline),
                  tooltip: 'Delete this server',
                  onPressed: _deleteServer,
                ),
            ],
          ),
          const SizedBox(height: 16),

          DropdownButtonFormField<MinecraftEdition>(
            key: ValueKey(_selectedEdition),
            initialValue: _selectedEdition,
            decoration: const InputDecoration(
              labelText: 'Minecraft Edition',
              border: OutlineInputBorder(),
            ),
            items: MinecraftEdition.values
                .map((edition) => DropdownMenuItem(
                      value: edition,
                      child: Text(edition.label),
                    ))
                .toList(),
            onChanged: (MinecraftEdition? edition) {
              if (edition != null) {
                setState(() => _selectedEdition = edition);
              }
            },
          ),
          Padding(
            padding: const EdgeInsets.only(top: 6, left: 12, right: 12),
            child: Text(
              'The bridge must use the same edition. Java bridges send commands through RCON.',
              style: Theme.of(context).textTheme.bodySmall,
            ),
          ),
          const SizedBox(height: 10),

          // Alias Input
          TextField(
            controller: _aliasController,
            decoration: const InputDecoration(
              labelText: 'Alias',
              border: OutlineInputBorder(),
            ),
          ),
          const SizedBox(height: 10),

          // IP Input
          TextField(
            controller: _ipController,
            decoration: const InputDecoration(
              labelText: 'IP / Hostname',
              border: OutlineInputBorder(),
            ),
            onChanged: (_) =>
                setState(() {}), // Keep the connection preview in sync
          ),
          const SizedBox(height: 10),

          // Port Input
          TextField(
            controller: _portController,
            decoration: const InputDecoration(
              labelText: 'Port',
              border: OutlineInputBorder(),
            ),
            keyboardType: TextInputType.number,
            onChanged: (_) =>
                setState(() {}), // Keep the connection preview in sync
          ),
          const SizedBox(height: 10),

          // Secret Key Input
          TextField(
            controller: _secretKeyController,
            decoration: InputDecoration(
              labelText: 'Secret Key',
              border: const OutlineInputBorder(),
              suffixIcon: IconButton(
                icon: Icon(
                  _isSecretVisible ? Icons.visibility : Icons.visibility_off,
                ),
                onPressed: () {
                  setState(() {
                    _isSecretVisible = !_isSecretVisible;
                  });
                },
              ),
            ),
            obscureText: !_isSecretVisible,
            enableSuggestions: false,
            autocorrect: false,
          ),
          const SizedBox(height: 10),

          // Connection Security Dropdown
          DropdownButtonFormField<ConnectionSecurity>(
            initialValue: _selectedSecurity,
            decoration: const InputDecoration(
              labelText: 'Connection Security',
              border: OutlineInputBorder(),
            ),
            items: _securityOptions
                .map((security) => DropdownMenuItem(
                      value: security,
                      child: Text(security.label),
                    ))
                .toList(),
            onChanged: (ConnectionSecurity? security) {
              if (security != null) {
                setState(() {
                  _selectedSecurity = security;
                });
              }
            },
          ),
          Padding(
            padding: const EdgeInsets.only(top: 6, left: 12, right: 12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  _selectedSecurity.description,
                  style: Theme.of(context).textTheme.bodySmall,
                ),
                const SizedBox(height: 4),
                // Showing the resulting address makes the difference between
                // an encrypted and an unencrypted connection visible before
                // saving, rather than after something goes wrong.
                Text(
                  _connectionPreview(),
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: _selectedSecurity.usesTls
                            ? null
                            : Theme.of(context).colorScheme.error,
                      ),
                ),
                Align(
                  alignment: Alignment.centerLeft,
                  child: TextButton.icon(
                    onPressed: () => UrlUtils.openDocumentation(
                      'guides/connection-security/',
                    ),
                    icon: const Icon(Icons.menu_book_outlined, size: 18),
                    label: const Text('Connection security guide'),
                  ),
                ),
                // Only worth explaining where someone would otherwise reach for
                // a certificate: it says nothing useful about an unencrypted
                // connection over a private network.
                if (!supportsCustomCertificate &&
                    _selectedSecurity.usesTls) ...[
                  const SizedBox(height: 4),
                  Text(
                    'Self-signed certificates cannot be loaded in a browser. Trust the certificate in the browser first by opening the server address, or use a server with a publicly trusted certificate.',
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                ],
              ],
            ),
          ),
          const SizedBox(height: 10),

          // Certificate File Input, only relevant when pinning a certificate
          if (_selectedSecurity.requiresCertificate) ...[
            TextField(
              controller: _certificateController,
              decoration: InputDecoration(
                labelText: 'Server Certificate',
                border: const OutlineInputBorder(),
                suffixIcon: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    IconButton(
                      icon: const Icon(Icons.folder_open),
                      onPressed: _pickCertificateFile,
                    ),
                    if (_certificateContent.isNotEmpty)
                      IconButton(
                        icon: const Icon(Icons.clear),
                        onPressed: () {
                          setState(() {
                            _certificateController.clear();
                            _certificateContent = '';
                            _updateCertificateMessage(); // Update message when clearing the certificate
                          });
                        },
                      ),
                  ],
                ),
              ),
              readOnly: true,
            ),
            const SizedBox(height: 10),
          ],

          // Max Output Lines Input
          TextField(
            controller: _maxOutLinesController,
            decoration: const InputDecoration(
              labelText: 'Max Output Lines',
              border: OutlineInputBorder(),
            ),
            keyboardType: TextInputType.number,
          ),
          const SizedBox(height: 10),

          // Save Settings Button
          ElevatedButton(
            onPressed: () async {
              // Check if maxOutLines is empty
              if (_maxOutLinesController.text.isEmpty) {
                // Show an error message if it's empty
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Max Output Lines cannot be empty.'),
                    backgroundColor: Colors.red,
                  ),
                );
                return; // Prevent saving if empty
              }

              // Validate that maxOutLines is a valid number
              int? maxOutLines;
              try {
                maxOutLines = int.parse(_maxOutLinesController.text);
              } catch (e) {
                // Show an error message if it's not a valid number
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Max Output Lines must be a valid number.'),
                    backgroundColor: Colors.red,
                  ),
                );
                return; // Prevent saving if not a valid number
              }

              // A pinned certificate is the only trust anchor in that mode, so
              // saving without one would leave the connection unable to verify
              // anything at all.
              if (_selectedSecurity.requiresCertificate &&
                  _certificateContent.isEmpty) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text(
                        'Load a server certificate, or pick another connection security option.'),
                    backgroundColor: Colors.red,
                  ),
                );
                return;
              }

              // Proceed with saving if validation passes
              await _model.setConnectionDetails(
                alias: _aliasController.text,
                ip: _ipController.text,
                secretKey: _secretKeyController.text,
                certificate: _certificateContent,
                port: int.parse(_portController.text),
                connectionSecurity: _selectedSecurity,
                minecraftEdition: _selectedEdition,
              );
              await _model.setMaxOutputLines(maxOutLines); // Save maxOutLines
              widget.onSettingsSaved();
            },
            child: const Text('Save Settings'),
          ),

          const SizedBox(height: 20),

          // Transfer Header
          Text(
            'Backup & Transfer',
            style: Theme.of(context).textTheme.headlineMedium,
          ),
          const SizedBox(height: 8),
          Text(
            'Move your saved servers to another device. Exports are encrypted with a passphrase, '
            'because they contain the secret keys that control your servers.',
            style: Theme.of(context).textTheme.bodySmall,
          ),
          Align(
            alignment: Alignment.centerLeft,
            child: TextButton.icon(
              onPressed: () => UrlUtils.openDocumentation(
                'guides/backup-transfer/',
              ),
              icon: const Icon(Icons.menu_book_outlined, size: 18),
              label: const Text('Backup and transfer guide'),
            ),
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              OutlinedButton.icon(
                onPressed: _busy ? null : () => _export(toClipboard: true),
                icon: const Icon(Icons.copy_all),
                label: const Text('Copy config'),
              ),
              OutlinedButton.icon(
                onPressed: _busy ? null : _importFromClipboard,
                icon: const Icon(Icons.content_paste),
                label: const Text('Paste config'),
              ),
              OutlinedButton.icon(
                onPressed: _busy ? null : () => _export(toClipboard: false),
                icon: const Icon(Icons.save_alt),
                label: const Text('Export file'),
              ),
              OutlinedButton.icon(
                onPressed: _busy ? null : _importFromFile,
                icon: const Icon(Icons.folder_open),
                label: const Text('Import file'),
              ),
            ],
          ),
          if (_busy)
            const Padding(
              padding: EdgeInsets.only(top: 12),
              child: LinearProgressIndicator(),
            ),

          const SizedBox(height: 20),

          // Appearance Settings Header
          Text(
            'Appearance Settings',
            style: Theme.of(context).textTheme.headlineMedium,
          ),
          const SizedBox(height: 16),

          // Theme Mode Dropdown
          const Text('Theme Mode'),
          DropdownButton<ThemeMode>(
            value: _selectedThemeMode,
            items: const [
              DropdownMenuItem(
                value: ThemeMode.system,
                child: Text('System Default'),
              ),
              DropdownMenuItem(
                value: ThemeMode.light,
                child: Text('Light Mode'),
              ),
              DropdownMenuItem(
                value: ThemeMode.dark,
                child: Text('Dark Mode'),
              ),
            ],
            onChanged: (ThemeMode? mode) {
              if (mode != null) {
                setState(() {
                  _selectedThemeMode = mode;
                });
                _model.setThemeMode(mode);
              }
            },
          ),
          const SizedBox(height: 20),

          // Font Dropdown
          const Text('Font'),
          DropdownButton<String>(
            value: _selectedFont,
            items: const [
              DropdownMenuItem(
                value: 'Miracode',
                child: Text('Miracode'),
              ),
              DropdownMenuItem(
                value: 'Monocraft',
                child: Text('Monocraft'),
              ),
              DropdownMenuItem(
                value: 'Scientifica',
                child: Text('Scientifica'),
              ),
              DropdownMenuItem(
                value: 'Roboto',
                child: Text('Roboto'),
              ),
            ],
            onChanged: (String? font) {
              if (font != null) {
                setState(() {
                  _selectedFont = font;
                });
                _model.setFont(font);
                ThemeService.font = font;
              }
            },
          ),
          const SizedBox(height: 20),

          // Font Size Slider
          Text('Font Size: ${_currentFontSize.toStringAsFixed(1)}'),
          Slider(
            value: _currentFontSize,
            min: 12.0,
            max: 32.0,
            divisions: 20, // Allows step-by-step increments
            label: _currentFontSize.toStringAsFixed(1),
            onChanged: (value) {
              setState(() {
                _currentFontSize = value;
                _fontSizeController.text = value.toStringAsFixed(1);
                _model.setFontSize(value);
                ThemeService.fontSize = value;
              });
            },
          ),
          const SizedBox(height: 40),

          RichText(
            textAlign: TextAlign.center,
            text: TextSpan(
              style: Theme.of(context).textTheme.bodySmall,
              children: [
                TextSpan(
                  text: 'Admincraft',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: Colors.blue,
                        decoration: TextDecoration.underline,
                      ),
                  recognizer: TapGestureRecognizer()
                    ..onTap = () {
                      UrlUtils.openUrl(
                          'https://github.com/joanroig/admincraft');
                    },
                ),
                TextSpan(
                  text: ' v$_version+$_buildNumber by ',
                  style: Theme.of(context).textTheme.bodySmall,
                ),
                TextSpan(
                  text: '@joanroig',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: Colors.blue,
                        decoration: TextDecoration.underline,
                      ),
                  recognizer: TapGestureRecognizer()
                    ..onTap = () {
                      UrlUtils.openUrl('https://linktr.ee/joanroig');
                    },
                ),
              ],
            ),
          )
        ],
      ),
    );
  }
}
