import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Thin wrapper around [SharedPreferences].
///
/// Only lightweight key/value data lives here: the theme choice (so it
/// survives a restart) and the path of the last JSON export.
class PreferencesStore {
  PreferencesStore(this._prefs);

  static const String _themeKey = 'theme_mode';
  static const String _lastExportKey = 'last_export_path';

  final SharedPreferences _prefs;

  static Future<PreferencesStore> load() async {
    final prefs = await SharedPreferences.getInstance();
    return PreferencesStore(prefs);
  }

  /// Defaults to [ThemeMode.system] when nothing has been stored yet.
  ThemeMode get themeMode {
    switch (_prefs.getString(_themeKey)) {
      case 'light':
        return ThemeMode.light;
      case 'dark':
        return ThemeMode.dark;
      default:
        return ThemeMode.system;
    }
  }

  Future<void> setThemeMode(ThemeMode mode) {
    return _prefs.setString(_themeKey, mode.name);
  }

  String? get lastExportPath => _prefs.getString(_lastExportKey);

  Future<void> setLastExportPath(String path) {
    return _prefs.setString(_lastExportKey, path);
  }
}
