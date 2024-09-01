import 'dart:async';
import 'dart:io';

import 'package:admincraft/models/model.dart';
import 'package:admincraft/utils/url_utils.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
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
  final TextEditingController _hostnameController = TextEditingController();
  final TextEditingController _usernameController = TextEditingController();
  final TextEditingController _pemFileController = TextEditingController();
  final TextEditingController _portController = TextEditingController();
  final TextEditingController _commandPrefixController = TextEditingController();
  final TextEditingController _maxOutLinesController = TextEditingController();
  ThemeMode _selectedThemeMode = ThemeMode.system;
  late Model _model;
  String _version = '';
  String _buildNumber = '';

  @override
  void initState() {
    super.initState();
    _model = Provider.of<Model>(context, listen: false);
    _loadSettings();
    _loadAppInfo(); // Load app version and build number
  }

  Future<void> _loadSettings() async {
    _aliasController.text = _model.alias;
    _hostnameController.text = _model.hostname;
    _usernameController.text = _model.username;
    _pemFileController.text = _model.pemKeyContent.isEmpty ? '' : 'Key Loaded';
    _portController.text = _model.port.toString();
    _selectedThemeMode = _model.themeMode;
    _commandPrefixController.text = _model.commandPrefix;
    _maxOutLinesController.text = _model.maxOutLines.toString();
  }

  Future<void> _loadAppInfo() async {
    final packageInfo = await PackageInfo.fromPlatform();
    setState(() {
      _version = packageInfo.version;
      _buildNumber = packageInfo.buildNumber;
    });
  }

  Future<void> _pickPemFile() async {
    final result = await FilePicker.platform.pickFiles(type: FileType.custom, allowedExtensions: ['pem', 'key']);
    if (result != null) {
      final pemKeyContent = await File(result.files.single.path!).readAsString();
      setState(() {
        _pemFileController.text = 'Key Loaded';
      });

      _model.setConnectionDetails(
        alias: _aliasController.text,
        hostname: _hostnameController.text,
        username: _usernameController.text,
        pemKeyContent: pemKeyContent,
        port: int.parse(_portController.text),
        commandPrefix: _commandPrefixController.text,
      );
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
          Text(
            'Server Settings',
            style: Theme.of(context).textTheme.headlineMedium,
          ),
          const SizedBox(height: 16),

          // Alias Input
          TextField(
            controller: _aliasController,
            decoration: const InputDecoration(
              labelText: 'Alias',
              border: OutlineInputBorder(),
            ),
          ),
          const SizedBox(height: 10),

          // Hostname Input
          TextField(
            controller: _hostnameController,
            decoration: const InputDecoration(
              labelText: 'IP / Hostname',
              border: OutlineInputBorder(),
            ),
          ),
          const SizedBox(height: 10),

          // Username Input
          TextField(
            controller: _usernameController,
            decoration: const InputDecoration(
              labelText: 'Username',
              border: OutlineInputBorder(),
            ),
          ),
          const SizedBox(height: 10),

          // PEM File Input
          TextField(
            controller: _pemFileController,
            decoration: InputDecoration(
              labelText: 'PEM Key',
              border: const OutlineInputBorder(),
              suffixIcon: IconButton(
                icon: const Icon(Icons.folder_open),
                onPressed: _pickPemFile,
              ),
            ),
            readOnly: true,
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
          ),
          const SizedBox(height: 10),

          // Command Prefix Input
          TextField(
            controller: _commandPrefixController,
            decoration: const InputDecoration(
              labelText: 'Command Prefix',
              border: OutlineInputBorder(),
            ),
          ),
          const SizedBox(height: 10),

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

              // Proceed with saving if validation passes
              await _model.setConnectionDetails(
                alias: _aliasController.text,
                hostname: _hostnameController.text,
                username: _usernameController.text,
                pemKeyContent: _model.pemKeyContent,
                port: int.parse(_portController.text),
                commandPrefix: _commandPrefixController.text,
              );
              await _model.setMaxOutputLines(maxOutLines); // Save maxOutLines
              widget.onSettingsSaved();
            },
            child: const Text('Save Settings'),
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

          const SizedBox(height: 40),

// At the bottom of your Column widget
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
                      UrlUtils.openUrl('https://github.com/joanroig/admincraft');
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
