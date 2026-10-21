import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

import 'app_settings.dart';
import 'data/country_repository.dart';
import 'screens/home_screen.dart';
import 'theme/app_theme.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // No celular o sqflite funciona direto; no desktop (testes) usa FFI.
  if (!kIsWeb && (Platform.isLinux || Platform.isWindows || Platform.isMacOS)) {
    sqfliteFfiInit();
    databaseFactory = databaseFactoryFfi;
  }

  final settings = await AppSettings.load();
  await CountryRepository.instance.load();
  runApp(QFlagsApp(settings: settings));
}

class QFlagsApp extends StatelessWidget {
  const QFlagsApp({super.key, required this.settings});

  final AppSettings settings;

  @override
  Widget build(BuildContext context) => SettingsScope(
        settings: settings,
        child: ListenableBuilder(
          listenable: settings,
          builder: (context, _) => MaterialApp(
            title: 'QFlags',
            debugShowCheckedModeBanner: false,
            theme: buildTheme(Brightness.light),
            darkTheme: buildTheme(Brightness.dark),
            themeMode: settings.themeMode,
            home: const HomeScreen(),
          ),
        ),
      );
}
