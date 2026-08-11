import 'package:admincraft/models/model.dart';
import 'package:admincraft/services/theme_service.dart';
import 'package:admincraft/utils/toast_utils.dart';
import 'package:admincraft/utils/url_utils.dart';
import 'package:flutter/material.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:provider/provider.dart';

class PreferencesView extends StatefulWidget {
  const PreferencesView({super.key});

  @override
  State<PreferencesView> createState() => _PreferencesViewState();
}

class _PreferencesViewState extends State<PreferencesView> {
  final _maxLinesController = TextEditingController();
  late ThemeMode _themeMode;
  late String _font;
  late double _fontSize;
  String _version = '';

  Model get _model => context.read<Model>();

  @override
  void initState() {
    super.initState();
    final model = context.read<Model>();
    _themeMode = model.themeMode;
    _font = model.font;
    _fontSize = model.fontSize;
    _maxLinesController.text = model.maxOutLines.toString();
    _loadVersion();
  }

  Future<void> _loadVersion() async {
    final info = await PackageInfo.fromPlatform();
    if (!mounted) return;
    setState(() => _version = '${info.version}+${info.buildNumber}');
  }

  Future<void> _saveConsolePreferences() async {
    final lines = int.tryParse(_maxLinesController.text);
    if (lines == null || lines < 100) {
      ToastUtils.showToastError('Use at least 100 output lines.');
      return;
    }
    await _model.setMaxOutputLines(lines);
    ToastUtils.showToastSuccess('Console preferences saved.');
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 820),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text('Preferences',
                  style: Theme.of(context).textTheme.headlineMedium),
              const SizedBox(height: 4),
              Text(
                'These settings apply to Admincraft on this device, not to one server.',
                style: Theme.of(context).textTheme.bodyMedium,
              ),
              const SizedBox(height: 16),
              _PreferenceCard(
                title: 'Appearance',
                subtitle: 'Theme and typography across the app.',
                child: Column(
                  children: [
                    DropdownButtonFormField<ThemeMode>(
                      initialValue: _themeMode,
                      decoration: const InputDecoration(labelText: 'Theme'),
                      items: const [
                        DropdownMenuItem(
                            value: ThemeMode.system,
                            child: Text('System default')),
                        DropdownMenuItem(
                            value: ThemeMode.light, child: Text('Light')),
                        DropdownMenuItem(
                            value: ThemeMode.dark, child: Text('Dark')),
                      ],
                      onChanged: (value) {
                        if (value == null) return;
                        setState(() => _themeMode = value);
                        _model.setThemeMode(value);
                      },
                    ),
                    const SizedBox(height: 12),
                    DropdownButtonFormField<String>(
                      initialValue: _font,
                      decoration: const InputDecoration(labelText: 'Font'),
                      items: const [
                        DropdownMenuItem(
                            value: 'Miracode', child: Text('Miracode')),
                        DropdownMenuItem(
                            value: 'Monocraft', child: Text('Monocraft')),
                        DropdownMenuItem(
                            value: 'Scientifica', child: Text('Scientifica')),
                        DropdownMenuItem(
                            value: 'Roboto', child: Text('Roboto')),
                      ],
                      onChanged: (value) {
                        if (value == null) return;
                        setState(() => _font = value);
                        ThemeService.font = value;
                        _model.setFont(value);
                      },
                    ),
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        const Expanded(child: Text('Font size')),
                        Text(_fontSize.toStringAsFixed(0)),
                      ],
                    ),
                    Slider(
                      value: _fontSize,
                      min: 12,
                      max: 32,
                      divisions: 20,
                      label: _fontSize.toStringAsFixed(0),
                      onChanged: (value) {
                        setState(() => _fontSize = value);
                        ThemeService.fontSize = value;
                        _model.setFontSize(value);
                      },
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 14),
              _PreferenceCard(
                title: 'Console behavior',
                subtitle: 'Local display limits for terminal output.',
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: TextField(
                        controller: _maxLinesController,
                        keyboardType: TextInputType.number,
                        decoration: const InputDecoration(
                            labelText: 'Maximum output lines'),
                      ),
                    ),
                    const SizedBox(width: 10),
                    FilledButton(
                      onPressed: _saveConsolePreferences,
                      child: const Text('Save'),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 14),
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(18),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('About Admincraft',
                          style: Theme.of(context).textTheme.titleMedium),
                      const SizedBox(height: 6),
                      Text(_version.isEmpty
                          ? 'Loading version…'
                          : 'Version $_version'),
                      const SizedBox(height: 12),
                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: [
                          OutlinedButton.icon(
                            onPressed: () => UrlUtils.openDocumentation(),
                            icon: const Icon(Icons.menu_book_outlined),
                            label: const Text('Documentation'),
                          ),
                          OutlinedButton.icon(
                            onPressed: () => UrlUtils.openUrl(
                                'https://github.com/joanroig/admincraft'),
                            icon: const Icon(Icons.code),
                            label: const Text('GitHub'),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  void dispose() {
    _maxLinesController.dispose();
    super.dispose();
  }
}

class _PreferenceCard extends StatelessWidget {
  final String title;
  final String subtitle;
  final Widget child;

  const _PreferenceCard({
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
