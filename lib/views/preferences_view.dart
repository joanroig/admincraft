import 'package:admincraft/models/app_theme.dart';
import 'package:admincraft/controllers/notification_controller.dart';
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
  final _consoleFilterController = TextEditingController();
  late AppTheme _appTheme;
  late ThemeMode _themeMode;
  late String _font;
  late double _fontSize;
  late String _terminalFont;
  late double _terminalFontSize;
  late bool _terminalAutoScroll;
  late String _timestampMode;
  String _version = '';
  bool _themesExpanded = false;

  Model get _model => context.read<Model>();

  /// The themes to draw: one row of them until the picker is expanded.
  ///
  /// The selected theme is always among them. Without that it can sit in a
  /// hidden row, and the collapsed picker then shows no selection at all,
  /// which reads as though nothing is chosen.
  List<AppTheme> _visibleThemes(int columns) {
    if (_themesExpanded || AppTheme.values.length <= columns) {
      return AppTheme.values;
    }
    final row = AppTheme.values.take(columns).toList();
    if (!row.contains(_appTheme)) row[row.length - 1] = _appTheme;
    return row;
  }

  @override
  void initState() {
    super.initState();
    final model = context.read<Model>();
    _appTheme = model.appTheme;
    _themeMode = model.themeMode;
    _font = model.font;
    _fontSize = model.fontSize;
    _terminalFont = model.terminalFont;
    _terminalFontSize = model.terminalFontSize;
    _terminalAutoScroll = model.terminalAutoScroll;
    _timestampMode = model.consoleTimestampMode;
    _maxLinesController.text = model.maxOutLines.toString();
    _consoleFilterController.text = model.consoleFilterPattern;
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
    await _model.setTerminalFont(_terminalFont);
    await _model.setTerminalFontSize(_terminalFontSize);
    await _model.setTerminalAutoScroll(_terminalAutoScroll);
    await _model.setConsoleTimestampMode(_timestampMode);
    await _model.setConsoleFilterPattern(_consoleFilterController.text.trim());
    ToastUtils.showToastSuccess('Console preferences saved.');
  }

  @override
  Widget build(BuildContext context) {
    final notifications = context.watch<NotificationController?>();
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 820),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                'Preferences',
                style: Theme.of(context).textTheme.headlineMedium,
              ),
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
                    Row(
                      children: [
                        // Expanded rather than Flexible plus a Spacer: both
                        // default to flex 1, so they split the free space
                        // between them and leave the button mid-card instead
                        // of against the right edge. Taking all of it here
                        // also lets the label ellipsize rather than overflow.
                        Expanded(
                          child: Text(
                            'Color theme',
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: Theme.of(context).textTheme.labelLarge,
                          ),
                        ),
                        TextButton.icon(
                          // Not prefixed 'app-theme-', which identifies the
                          // tiles themselves and is counted as such.
                          key: const ValueKey('theme-expand-toggle'),
                          onPressed: () => setState(
                            () => _themesExpanded = !_themesExpanded,
                          ),
                          icon: Icon(
                            _themesExpanded
                                ? Icons.expand_less
                                : Icons.expand_more,
                          ),
                          label: Text(
                            _themesExpanded
                                ? 'Show less'
                                : 'All ${AppTheme.values.length}',
                          ),
                        ),
                      ],
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
                            for (final theme in _visibleThemes(columns))
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
                      decoration: const InputDecoration(
                        labelText: 'Appearance mode',
                      ),
                      items: const [
                        DropdownMenuItem(
                          value: ThemeMode.system,
                          child: Text('System default'),
                        ),
                        DropdownMenuItem(
                          value: ThemeMode.light,
                          child: Text('Light'),
                        ),
                        DropdownMenuItem(
                          value: ThemeMode.dark,
                          child: Text('Dark'),
                        ),
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
                subtitle:
                    'Typography, filtering and scrolling for terminal output.',
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    LayoutBuilder(
                      builder: (context, constraints) {
                        final fieldWidth = constraints.maxWidth < 520
                            ? constraints.maxWidth
                            : (constraints.maxWidth - 10) / 2;
                        return Wrap(
                          spacing: 10,
                          runSpacing: 12,
                          children: [
                            SizedBox(
                              width: fieldWidth,
                              child: TextField(
                                controller: _maxLinesController,
                                keyboardType: TextInputType.number,
                                decoration: const InputDecoration(
                                  labelText: 'Maximum output lines',
                                ),
                              ),
                            ),
                            SizedBox(
                              width: fieldWidth,
                              child: DropdownButtonFormField<String>(
                                initialValue: _timestampMode,
                                decoration: const InputDecoration(
                                  labelText: 'Timestamps',
                                ),
                                items: const [
                                  DropdownMenuItem(
                                    value: 'full',
                                    child: Text('Full'),
                                  ),
                                  DropdownMenuItem(
                                    value: 'short',
                                    child: Text('Short'),
                                  ),
                                  DropdownMenuItem(
                                    value: 'hidden',
                                    child: Text('Hidden'),
                                  ),
                                ],
                                onChanged: (value) {
                                  if (value != null) {
                                    setState(() => _timestampMode = value);
                                  }
                                },
                              ),
                            ),
                          ],
                        );
                      },
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: _consoleFilterController,
                      decoration: const InputDecoration(
                        labelText: 'Only show lines containing (optional)',
                        helperText:
                            'Case-insensitive; leave empty to show everything.',
                      ),
                    ),
                    const SizedBox(height: 12),
                    DropdownButtonFormField<String>(
                      initialValue: _terminalFont,
                      decoration: const InputDecoration(
                        labelText: 'Terminal font',
                      ),
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
                      onChanged: (value) {
                        if (value != null) {
                          setState(() => _terminalFont = value);
                        }
                      },
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        const Expanded(child: Text('Terminal font size')),
                        Text(_terminalFontSize.toStringAsFixed(0)),
                      ],
                    ),
                    Slider(
                      value: _terminalFontSize,
                      min: 10,
                      max: 28,
                      divisions: 18,
                      label: _terminalFontSize.toStringAsFixed(0),
                      onChanged: (value) =>
                          setState(() => _terminalFontSize = value),
                    ),
                    SwitchListTile(
                      contentPadding: EdgeInsets.zero,
                      title: const Text('Automatically scroll to new output'),
                      value: _terminalAutoScroll,
                      onChanged: (value) =>
                          setState(() => _terminalAutoScroll = value),
                    ),
                    Align(
                      alignment: Alignment.centerRight,
                      child: FilledButton(
                        onPressed: _saveConsolePreferences,
                        child: const Text('Save console preferences'),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 14),
              if (notifications != null) ...[
                _PreferenceCard(
                  title: 'Notifications',
                  subtitle:
                      'Every event stays in the notification history even when popups are hidden.',
                  child: SwitchListTile(
                    contentPadding: EdgeInsets.zero,
                    title: const Text('Show notification popups'),
                    subtitle: const Text(
                      'Connection events and errors will still be saved behind the bell icon.',
                    ),
                    value: notifications.popupsEnabled,
                    onChanged: notifications.setPopupsEnabled,
                  ),
                ),
                const SizedBox(height: 14),
              ],
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(18),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'About Admincraft',
                        style: Theme.of(context).textTheme.titleMedium,
                      ),
                      const SizedBox(height: 6),
                      Text(
                        _version.isEmpty
                            ? 'Loading version…'
                            : 'Version $_version',
                      ),
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
                              'https://github.com/joanroig/admincraft',
                            ),
                            icon: const Icon(Icons.code),
                            label: const Text('GitHub'),
                          ),
                        ],
                      ),
                      const SizedBox(height: 14),
                      // Mojang's usage guidelines ask fan projects to say this,
                      // and the app leans on Minecraft's name and look
                      // throughout, so it belongs in the app and not only in
                      // the documentation someone may never read.
                      Text(
                        'NOT AN OFFICIAL MINECRAFT PRODUCT. NOT APPROVED BY OR '
                        'ASSOCIATED WITH MOJANG OR MICROSOFT.',
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: Theme.of(context).colorScheme.onSurfaceVariant,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Minecraft is a trademark of Mojang Synergies AB. '
                        'Admincraft is an independent project.',
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: Theme.of(context).colorScheme.onSurfaceVariant,
                        ),
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
    _consoleFilterController.dispose();
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
