import 'package:admincraft/controllers/connection_controller.dart';
import 'package:admincraft/controllers/google_drive_sync_controller.dart';
import 'package:admincraft/services/persistence_service.dart';
import 'package:admincraft/services/theme_service.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:toastification/toastification.dart';

import 'models/model.dart';
import 'services/secret_migration.dart';
import 'services/secure_value_store.dart';
import 'services/server_secrets.dart';
import 'views/tabs_view.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  final prefs = await SharedPreferences.getInstance();

  // Server keys and certificates live in the platform keystore, so they have to
  // be read before the model, which loads profiles synchronously.
  final secrets = await ServerSecrets.load(
    PersistenceService.storedServerIds(prefs),
    const PlatformSecureValueStore(),
  );
  final persistentDataManager = PersistenceService(prefs, secrets);

  // Move any profile still holding its key in plain storage, and only drop the
  // plain copy once the keystore proves it can hand the key back.
  await migrateServerSecrets(persistentDataManager, secrets);

  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(
          create: (context) => Model(persistentDataManager),
        ),
        ChangeNotifierProvider(
          create: (context) => ConnectionController(),
        ),
        ChangeNotifierProvider(
          create: (context) => GoogleDriveSyncController(prefs),
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
      dynamicSchemeVariant: model.appTheme.variant,
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
