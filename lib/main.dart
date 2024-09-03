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

  @override
  Widget build(BuildContext context) {
    final model = Provider.of<Model>(context);

    return ToastificationWrapper(
      child: MaterialApp(
        title: "Admincraft",
        themeMode: model.themeMode,
        theme: ThemeData.light().copyWith(
          textTheme: ThemeService.textThemeFromStyles(model).apply(
            bodyColor: Colors.black,
            displayColor: Colors.black,
          ),
        ),
        darkTheme: ThemeData.dark().copyWith(
          textTheme: ThemeService.textThemeFromStyles(model).apply(
            bodyColor: Colors.white,
            displayColor: Colors.white,
          ),
        ),
        home: const Tabs(),
      ),
    );
  }
}
