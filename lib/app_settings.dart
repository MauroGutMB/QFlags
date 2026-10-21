import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'l10n/strings.dart';

/// Preferências do jogador: tema, idioma e último nome usado no ranking.
class AppSettings extends ChangeNotifier {
  AppSettings._(this._prefs, this._themeMode, this._lang, this._lastName);

  static const _kTheme = 'theme_mode';
  static const _kLang = 'lang';
  static const _kName = 'last_name';

  final SharedPreferences _prefs;
  ThemeMode _themeMode;
  AppLang _lang;
  String _lastName;

  ThemeMode get themeMode => _themeMode;
  AppLang get lang => _lang;
  String get lastName => _lastName;

  static Future<AppSettings> load() async {
    final prefs = await SharedPreferences.getInstance();
    final theme = ThemeMode.values.asNameMap()[prefs.getString(_kTheme)] ??
        ThemeMode.system;
    final lang = AppLang.values.asNameMap()[prefs.getString(_kLang)] ??
        _systemLang();
    return AppSettings._(prefs, theme, lang, prefs.getString(_kName) ?? '');
  }

  static AppLang _systemLang() {
    final code = WidgetsBinding.instance.platformDispatcher.locale.languageCode;
    return code == 'pt' ? AppLang.pt : AppLang.en;
  }

  /// Alterna entre claro e escuro a partir do brilho que está na tela agora.
  void toggleTheme(Brightness current) {
    _themeMode = current == Brightness.dark ? ThemeMode.light : ThemeMode.dark;
    _prefs.setString(_kTheme, _themeMode.name);
    notifyListeners();
  }

  void toggleLang() {
    _lang = _lang == AppLang.pt ? AppLang.en : AppLang.pt;
    _prefs.setString(_kLang, _lang.name);
    notifyListeners();
  }

  void setLastName(String name) {
    _lastName = name;
    _prefs.setString(_kName, name);
  }
}

class SettingsScope extends InheritedNotifier<AppSettings> {
  const SettingsScope({
    super.key,
    required AppSettings settings,
    required super.child,
  }) : super(notifier: settings);

  static AppSettings of(BuildContext context) => context
      .dependOnInheritedWidgetOfExactType<SettingsScope>()!
      .notifier!;
}
