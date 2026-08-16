import 'dart:convert';
import 'dart:io';

import 'package:admincraft/controllers/google_drive_sync_controller.dart';
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

  GoogleDriveSyncController get _drive =>
      context.read<GoogleDriveSyncController>();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) _drive.initialize(_model);
    });
  }

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

  Future<void> _enableDriveUpload() async {
    final confirmed = await DialogUtils.confirmAction(
      context,
      title: 'Upload this device and enable sync?',
      message:
          'These server profiles will replace any existing Admincraft copy in Google Drive.',
      confirmLabel: 'Continue',
    );
    if (!confirmed || !mounted) return;
    final passphrase = await DialogUtils.promptForPassphrase(
      context,
      title: 'Encrypt Google Drive sync',
      message:
          'Choose the passphrase for every synced device. It will be kept in secure storage on this device.',
      confirm: true,
    );
    if (passphrase == null || !mounted) return;
    await _driveAction(
      () => _drive.enableWithUpload(_model, passphrase),
      'Google Drive sync enabled with this device.',
    );
  }

  Future<void> _enableDriveDownload() async {
    final confirmed = await DialogUtils.confirmAction(
      context,
      title: 'Use the Google Drive copy?',
      message:
          'The Drive profiles will replace the server profiles on this device.',
      confirmLabel: 'Continue',
    );
    if (!confirmed || !mounted) return;
    final passphrase = await DialogUtils.promptForPassphrase(
      context,
      title: 'Restore Google Drive configuration',
      message: 'Enter the sync passphrase used on the device that uploaded it.',
      confirm: false,
    );
    if (passphrase == null || !mounted) return;
    await _driveAction(
      () => _drive.enableWithDownload(_model, passphrase),
      'Google Drive configuration restored and sync enabled.',
    );
  }

  Future<void> _driveAction(
    Future<void> Function() action,
    String success,
  ) async {
    try {
      await action();
      ToastUtils.showToastSuccess(success);
    } catch (_) {
      if (_drive.error != null) ToastUtils.showToastError(_drive.error!);
    }
  }

  Future<void> _forceDriveUpload() async {
    final confirmed = await DialogUtils.confirmAction(
      context,
      title: 'Replace the Google Drive copy?',
      message: 'The profiles on this device will become the synced copy.',
      confirmLabel: 'Upload',
    );
    if (!confirmed || !mounted) return;
    await _driveAction(
      () => _drive.uploadNow(_model),
      'This device was uploaded to Google Drive.',
    );
  }

  Future<void> _forceDriveDownload() async {
    final confirmed = await DialogUtils.confirmAction(
      context,
      title: 'Replace this device from Google Drive?',
      message: 'The synced Drive profiles will replace the local profiles.',
      confirmLabel: 'Download',
    );
    if (!confirmed || !mounted) return;
    await _driveAction(
      () => _drive.downloadNow(_model),
      'Google Drive configuration restored.',
    );
  }

  String _lastSyncLabel(DateTime? value) {
    if (value == null) return 'Not synced on this device yet';
    final difference = DateTime.now().toUtc().difference(value);
    if (difference.inMinutes < 1) return 'Synced just now';
    if (difference.inHours < 1) {
      return 'Synced ${difference.inMinutes} minutes ago';
    }
    if (difference.inDays < 1) {
      return 'Synced ${difference.inHours} hours ago';
    }
    return 'Last synced ${value.toLocal()}';
  }

  Widget _cloudSyncCard(GoogleDriveSyncController drive) {
    final signInButton = drive.buildSignInButton();
    final account = drive.email;
    final subtitle = !drive.configured
        ? 'This build has no Google OAuth client IDs. Add them at build time to enable Drive.'
        : !drive.signedIn
            ? 'Sign in to keep the same encrypted server profiles on every device.'
            : drive.automaticSyncEnabled
                ? '${account == null ? 'Connected to Google Drive' : 'Connected as $account'} · ${_lastSyncLabel(drive.lastSyncAt)}'
                : '${account ?? 'Google account connected'} · Choose which copy to use first.';

    final actions = <Widget>[];
    if (drive.configured && !drive.signedIn) {
      if (signInButton != null) {
        actions.add(signInButton);
      } else {
        actions.add(
          FilledButton.icon(
            onPressed: drive.busy ? null : drive.signIn,
            icon: const Icon(Icons.login),
            label: const Text('Sign in with Google'),
          ),
        );
      }
    } else if (drive.signedIn && !drive.automaticSyncEnabled) {
      actions.addAll([
        FilledButton.icon(
          onPressed: drive.busy ? null : _enableDriveUpload,
          icon: const Icon(Icons.cloud_upload_outlined),
          label: const Text('Upload this device'),
        ),
        OutlinedButton.icon(
          onPressed: drive.busy ? null : _enableDriveDownload,
          icon: const Icon(Icons.cloud_download_outlined),
          label: const Text('Use Drive copy'),
        ),
        TextButton(
          onPressed: drive.busy ? null : drive.disconnect,
          child: const Text('Sign out'),
        ),
      ]);
    } else if (drive.signedIn && drive.automaticSyncEnabled) {
      actions.addAll([
        FilledButton.icon(
          onPressed: drive.busy
              ? null
              : () => _driveAction(
                    () => drive.syncNow(_model),
                    'Google Drive is up to date.',
                  ),
          icon: const Icon(Icons.sync),
          label: const Text('Sync now'),
        ),
        OutlinedButton.icon(
          onPressed: drive.busy ? null : _forceDriveUpload,
          icon: const Icon(Icons.cloud_upload_outlined),
          label: const Text('Upload'),
        ),
        OutlinedButton.icon(
          onPressed: drive.busy ? null : _forceDriveDownload,
          icon: const Icon(Icons.cloud_download_outlined),
          label: const Text('Download'),
        ),
        TextButton(
          onPressed: drive.busy ? null : drive.disconnect,
          child: const Text('Disconnect'),
        ),
      ]);
    }

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            LayoutBuilder(
              builder: (context, constraints) {
                final status = !drive.configured
                    ? const Chip(label: Text('Setup required'))
                    : drive.automaticSyncEnabled
                        ? const Chip(label: Text('Automatic'))
                        : null;
                final icon = Icon(
                  Icons.cloud_sync_outlined,
                  size: 30,
                  color: Theme.of(context).colorScheme.primary,
                );
                final title = Text(
                  'Google Drive sync',
                  style: Theme.of(context).textTheme.titleMedium,
                );
                if (constraints.maxWidth < 520) {
                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Row(
                        children: [
                          icon,
                          const SizedBox(width: 12),
                          Expanded(child: title),
                          if (status != null) status,
                        ],
                      ),
                      const SizedBox(height: 8),
                      Text(
                        subtitle,
                        style: Theme.of(context).textTheme.bodySmall,
                      ),
                    ],
                  );
                }
                return Row(
                  children: [
                    icon,
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          title,
                          const SizedBox(height: 3),
                          Text(
                            subtitle,
                            style: Theme.of(context).textTheme.bodySmall,
                          ),
                        ],
                      ),
                    ),
                    if (status != null) status,
                  ],
                );
              },
            ),
            if (drive.error != null) ...[
              const SizedBox(height: 12),
              Text(
                drive.error!,
                style: TextStyle(color: Theme.of(context).colorScheme.error),
              ),
            ],
            if (drive.busy) ...[
              const SizedBox(height: 12),
              const LinearProgressIndicator(),
            ],
            if (actions.isNotEmpty) ...[
              const SizedBox(height: 16),
              Wrap(spacing: 8, runSpacing: 8, children: actions),
            ],
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final drive = context.watch<GoogleDriveSyncController>();
    final busy = _busy || drive.busy;
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
              if (busy) const LinearProgressIndicator(),
              if (busy) const SizedBox(height: 12),
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
                              busy ? null : () => _export(toClipboard: true),
                          icon: const Icon(Icons.copy),
                          label: const Text('Copy config'),
                        ),
                        OutlinedButton.icon(
                          onPressed: busy ? null : _importFromClipboard,
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
                              busy ? null : () => _export(toClipboard: false),
                          icon: const Icon(Icons.save_alt),
                          label: const Text('Export file'),
                        ),
                        OutlinedButton.icon(
                          onPressed: busy ? null : _importFromFile,
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
                      : Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            panels.first,
                            const SizedBox(height: 12),
                            panels.last,
                          ],
                        );
                },
              ),
              const SizedBox(height: 14),
              _cloudSyncCard(drive),
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
