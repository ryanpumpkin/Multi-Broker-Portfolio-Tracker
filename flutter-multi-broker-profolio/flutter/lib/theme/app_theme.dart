import 'package:flutter/material.dart';

/// Material 3 light + dark themes for the application.
///
/// The themes are derived from a single seed color so that they remain
/// visually consistent. [themeModeDefault] is the default `ThemeMode` used
/// before the user has expressed a preference; it follows the system.
class AppTheme {
  AppTheme._();

  /// Brand seed color. Detailed branding is deferred to the design module;
  /// this seed is a neutral choice that works in both light and dark modes.
  static const Color seedColor = Color(0xFF1565C0);

  /// Default theme mode — follow the host operating system.
  static const ThemeMode themeModeDefault = ThemeMode.system;

  /// Light Material 3 theme.
  static ThemeData light() => _build(Brightness.light);

  /// Dark Material 3 theme.
  static ThemeData dark() => _build(Brightness.dark);

  static ThemeData _build(Brightness brightness) {
    final colorScheme = ColorScheme.fromSeed(
      seedColor: seedColor,
      brightness: brightness,
    );
    return ThemeData(
      useMaterial3: true,
      brightness: brightness,
      colorScheme: colorScheme,
      visualDensity: VisualDensity.adaptivePlatformDensity,
    );
  }

  /// Resolves a [ThemeMode] from a string identifier. Unknown values fall
  /// back to [themeModeDefault]. Used when reading the user setting from
  /// persistent storage.
  static ThemeMode resolveMode(String? value) {
    switch (value) {
      case 'light':
        return ThemeMode.light;
      case 'dark':
        return ThemeMode.dark;
      case 'system':
        return ThemeMode.system;
      default:
        return themeModeDefault;
    }
  }

  /// Serializes a [ThemeMode] to a stable string identifier.
  static String encodeMode(ThemeMode mode) {
    switch (mode) {
      case ThemeMode.light:
        return 'light';
      case ThemeMode.dark:
        return 'dark';
      case ThemeMode.system:
        return 'system';
    }
  }
}
