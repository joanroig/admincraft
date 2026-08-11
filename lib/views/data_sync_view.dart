import 'dart:convert';
import 'dart:io';

import 'package:admincraft/models/model.dart';
import 'package:admincraft/services/config_file.dart';
import 'package:admincraft/services/config_transfer.dart';
import 'package:admincraft/utils/dialog_utils.dart';
import 'package:admincraft/utils/toast_utils.dart';
import 'package:admincraft/utils/url_utils.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

class DataSyncView extends StatefulWidget {
  final Future<void> Function() onServersChanged;

  const DataSyncView({super.key, required this.onServersChanged});

  @override
  State<DataSyncView> createState() => _DataSyncViewState();
}

class _DataSyncViewState extends State<DataSyncView> {
  bool _busy = false;

  Model get _model => context.read<Model>();

  Future<void> _export({required bool toClipboard}) async {
    final passphrase = await DialogUtils.promptForPassphrase(
      context,
      title: 'Export servers',
      message:
          'Choose a passphrase. You will need the same one to import this backup.',
      confirm: true,
    );
    if (passphrase == null || !mounted) return;

    setState(() => _busy = true);
    try {
      final blob = await ConfigTransfer.export(_model.servers, passphrase);
      if (toClipboard) {
        await Clipboard.setData(ClipboardData(text: blob));
        ToastUtils.showToastSuccess('Encrypted config copied.');
      } else {
        final path = await saveConfigFile(ConfigTransfer.fileName(), blob);
        if (path != null) ToastUtils.showToastSuccess('Backup saved to $path');
      }
    } catch (error) {
      ToastUtils.showToastError('Export failed: $error');
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
    } catch (error) {
      ToastUtils.showToastError('Could not read the clipboard: $error');
    }
  }

  Future<void> _importFromFile() async {
    try {
      final result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: const ['json'],
        withData: true,
      );
      if (result == null) return;
      final file = result.files.single;
      final blob = file.bytes != null
          ? utf8.decode(file.bytes!)
          : await File(file.path!).readAsString();
      await _import(blob);
    } catch (error) {
      ToastUtils.showToastError('Could not read the config file: $error');
    }
  }

  Future<void> _import(String blob) async {
    final passphrase = await DialogUtils.promptForPassphrase(
      context,
      title: 'Import servers',
      message: 'Enter the passphrase used when this backup was exported.',
      confirm: false,
    );
    if (passphrase == null || !mounted) return;

    setState(() => _busy = true);
    try {
      final servers = await ConfigTransfer.import(blob, passphrase);
      if (servers.isEmpty) {
        throw const ConfigTransferException(
            'This backup does not contain any servers.');
      }
      if (!mounted) return;
      final confirmed = await DialogUtils.confirmAction(
        context,
        title: 'Import ${servers.length} server(s)?',
        message:
            'Matching profiles will be updated. Other saved servers will remain.',
        confirmLabel: 'Import',
      );
      if (!confirmed) return;

      final result = await _model.importServers(servers);
      await widget.onServersChanged();
      ToastUtils.showToastSuccess(
        'Imported ${result.added} new and updated ${result.updated} server(s).',
      );
    } on ConfigTransferException catch (error) {
      ToastUtils.showToastError(error.message);
    } catch (error) {
      ToastUtils.showToastError('Import failed: $error');
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 920),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Data & Sync',
                            style: Theme.of(context).textTheme.headlineMedium),
                        const SizedBox(height: 4),
                        Text(
                          'Move or protect every saved server profile.',
                          style: Theme.of(context).textTheme.bodyMedium,
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    tooltip: 'Backup and transfer guide',
                    onPressed: () =>
                        UrlUtils.openDocumentation('guides/backup-transfer/'),
                    icon: const Icon(Icons.help_outline),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              if (_busy) const LinearProgressIndicator(),
              if (_busy) const SizedBox(height: 12),
              LayoutBuilder(
                builder: (context, constraints) {
                  final wide = constraints.maxWidth >= 680;
                  final panels = [
                    _TransferCard(
                      icon: Icons.copy_all_outlined,
                      title: 'Quick transfer',
                      description:
                          'Copy an encrypted configuration and paste it on another device.',
                      actions: [
                        FilledButton.icon(
                          onPressed:
                              _busy ? null : () => _export(toClipboard: true),
                          icon: const Icon(Icons.copy),
                          label: const Text('Copy config'),
                        ),
                        OutlinedButton.icon(
                          onPressed: _busy ? null : _importFromClipboard,
                          icon: const Icon(Icons.content_paste),
                          label: const Text('Paste config'),
                        ),
                      ],
                    ),
                    _TransferCard(
                      icon: Icons.file_download_outlined,
                      title: 'Backup file',
                      description:
                          'Keep a portable encrypted backup for offline transfer or recovery.',
                      actions: [
                        FilledButton.icon(
                          onPressed:
                              _busy ? null : () => _export(toClipboard: false),
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
                  ];
                  return wide
                      ? Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Expanded(child: panels.first),
                            const SizedBox(width: 12),
                            Expanded(child: panels.last),
                          ],
                        )
                      : Column(children: [
                          panels.first,
                          const SizedBox(height: 12),
                          panels.last,
                        ]);
                },
              ),
              const SizedBox(height: 14),
              const Card(
                child: ListTile(
                  contentPadding: EdgeInsets.all(16),
                  leading: Icon(Icons.cloud_sync_outlined),
                  title: Text('Automatic cloud sync'),
                  subtitle: Text(
                    'Google Drive sync can use the same encrypted payload in a future phase.',
                  ),
                  trailing: Chip(label: Text('Planned')),
                ),
              ),
              const SizedBox(height: 10),
              Card(
                color: Theme.of(context).colorScheme.secondaryContainer,
                child: const ListTile(
                  contentPadding: EdgeInsets.all(16),
                  leading: Icon(Icons.lock_outline),
                  title: Text('Your passphrase is never stored in the backup'),
                  subtitle: Text(
                    'Anyone importing it must know the passphrase you chose during export.',
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _TransferCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final String description;
  final List<Widget> actions;

  const _TransferCard({
    required this.icon,
    required this.title,
    required this.description,
    required this.actions,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(icon, size: 30, color: Theme.of(context).colorScheme.primary),
            const SizedBox(height: 14),
            Text(title, style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 5),
            Text(description, style: Theme.of(context).textTheme.bodySmall),
            const SizedBox(height: 20),
            Wrap(spacing: 8, runSpacing: 8, children: actions),
          ],
        ),
      ),
    );
  }
}
