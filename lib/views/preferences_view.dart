import 'package:admincraft/models/app_theme.dart';
import 'package:admincraft/models/model.dart';
import 'package:admincraft/services/theme_service.dart';
import 'package:admincraft/utils/toast_utils.dart';
import 'package:admincraft/utils/build_info.dart';
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
  late AppTheme _appTheme;
  late ThemeMode _themeMode;
  late String _font;
  late double _fontSize;
  String _version = '';

  Model get _model => context.read<Model>();

  @override
  void initState() {
    super.initState();
    final model = context.read<Model>();
    _appTheme = model.appTheme;
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
                    Align(
                      alignment: Alignment.centerLeft,
                      child: Text(
                        'Color theme',
                        style: Theme.of(context).textTheme.labelLarge,
                      ),
                    ),
                    const SizedBox(height: 8),
                    LayoutBuilder(
                      builder: (context, constraints) {
                        // Every breakpoint keeps a tile at roughly 100px or
                        // more, which is what the longest label needs. The
                        // icon stays 32px: it is 16x16 pixel art, so only
                        // multiples of 16 scale without blurring it.
                        final columns = constraints.maxWidth >= 880
                            ? 8
                            : constraints.maxWidth >= 720
                                ? 6
                                : constraints.maxWidth >= 440
                                    ? 4
                                    : 3;
                        const spacing = 8.0;
                        final width =
                            (constraints.maxWidth - spacing * (columns - 1)) /
                                columns;
                        return Wrap(
                          spacing: spacing,
                          runSpacing: spacing,
                          children: [
                            for (final theme in AppTheme.values)
                              SizedBox(
                                width: width,
                                child: _ThemeChoice(
                                  theme: theme,
                                  selected: _appTheme == theme,
                                  onTap: () {
                                    setState(() => _appTheme = theme);
                                    _model.setAppTheme(theme);
                                  },
                                ),
                              ),
                          ],
                        );
                      },
                    ),
                    const SizedBox(height: 16),
                    DropdownButtonFormField<ThemeMode>(
                      initialValue: _themeMode,
                      decoration:
                          const InputDecoration(labelText: 'Appearance mode'),
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
                      // Release builds carry the time they were made, so a
                      // report can identify the exact binary rather than a
                      // version several builds share.
                      if (BuildInfo.isKnown)
                        Tooltip(
                          message: BuildInfo.description!,
                          child: Text(
                            'Build ${BuildInfo.stamp}',
                            style: Theme.of(context).textTheme.bodySmall,
                          ),
                        ),
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

class _ThemeChoice extends StatelessWidget {
  final AppTheme theme;
  final bool selected;
  final VoidCallback onTap;

  const _ThemeChoice({
    required this.theme,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Material(
      color: selected ? scheme.primaryContainer : scheme.surfaceContainerLow,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(
          color: selected ? scheme.primary : scheme.outlineVariant,
          width: selected ? 2 : 1,
        ),
      ),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        key: ValueKey('app-theme-${theme.name}'),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 8),
          child: Column(
            children: [
              Image.asset(
                theme.logoAsset,
                // A multiple of 16 keeps the pixel grid exact.
                width: 32,
                height: 32,
                fit: BoxFit.fill,
                filterQuality: FilterQuality.none,
                isAntiAlias: false,
              ),
              const SizedBox(height: 4),
              Text(
                theme.label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: Theme.of(context).textTheme.labelMedium,
              ),
            ],
          ),
        ),
      ),
    );
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
