import 'package:admincraft/controllers/connection_controller.dart';
import 'package:admincraft/services/persistence_service.dart';
import 'package:admincraft/services/theme_service.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:toastification/toastification.dart';

import 'models/model.dart';
import 'views/tabs_view.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  final prefs = await SharedPreferences.getInstance();
  final persistentDataManager = PersistenceService(prefs);

  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(
          create: (context) => Model(persistentDataManager),
        ),
        ChangeNotifierProvider(
          create: (context) => ConnectionController(),
        ),
      ],
      child: const Admincraft(),
    ),
  );
}

class Admincraft extends StatelessWidget {
  const Admincraft({super.key});

  ThemeData _theme(Model model, Brightness brightness) {
    final scheme = ColorScheme.fromSeed(
      seedColor: model.appTheme.seedColor,
      brightness: brightness,
    );
    final base = ThemeData(
      useMaterial3: true,
      brightness: brightness,
      colorScheme: scheme,
    );

    return base.copyWith(
      scaffoldBackgroundColor: scheme.surface,
      textTheme: ThemeService.textThemeFromStyles(model).apply(
        bodyColor: scheme.onSurface,
        displayColor: scheme.onSurface,
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: scheme.surfaceContainerLowest,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: scheme.outlineVariant),
        ),
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 14, vertical: 13),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final model = Provider.of<Model>(context);

    return ToastificationWrapper(
      child: MaterialApp(
        title: "Admincraft",
        debugShowCheckedModeBanner: false,
        themeMode: model.themeMode,
        theme: _theme(model, Brightness.light),
        darkTheme: _theme(model, Brightness.dark),
        home: const Tabs(),
      ),
    );
  }
}
