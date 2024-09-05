import 'dart:async';

import 'package:admincraft/models/model.dart';
import 'package:admincraft/services/theme_service.dart';
import 'package:admincraft/utils/url_utils.dart';
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
  final TextEditingController _ipController = TextEditingController();
  final TextEditingController _portController = TextEditingController();
  final TextEditingController _secretKeyController = TextEditingController();
  final TextEditingController _maxOutLinesController = TextEditingController();
  ThemeMode _selectedThemeMode = ThemeMode.system;
  final TextEditingController _fontSizeController = TextEditingController();
  String _selectedFont = '';
  double _currentFontSize = 16.0;
  late Model _model;
  String _version = '';
  String _buildNumber = '';
  bool _isSecretVisible = false;

  @override
  void initState() {
    super.initState();
    _model = Provider.of<Model>(context, listen: false);
    _selectedFont = _model.font;
    _currentFontSize = _model.fontSize;
    _loadSettings();
    _loadAppInfo(); // Load app version and build number
  }

  Future<void> _loadSettings() async {
    _aliasController.text = _model.alias;
    _ipController.text = _model.ip;
    _portController.text = _model.port.toString();
    _secretKeyController.text = _model.secretKey;
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

          // IP Input
          TextField(
            controller: _ipController,
            decoration: const InputDecoration(
              labelText: 'IP / Hostname',
              border: OutlineInputBorder(),
            ),
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
                ip: _ipController.text,
                secretKey: _secretKeyController.text,
                port: int.parse(_portController.text),
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
