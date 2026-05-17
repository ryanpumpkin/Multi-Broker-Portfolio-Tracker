import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:multi_broker_portfolio/theme/app_theme.dart';

void main() {
  group('AppTheme', () {
    test('light theme is Material 3 with light brightness', () {
      final t = AppTheme.light();
      expect(t.useMaterial3, isTrue);
      expect(t.brightness, Brightness.light);
      expect(t.colorScheme.brightness, Brightness.light);
    });

    test('dark theme is Material 3 with dark brightness', () {
      final t = AppTheme.dark();
      expect(t.useMaterial3, isTrue);
      expect(t.brightness, Brightness.dark);
      expect(t.colorScheme.brightness, Brightness.dark);
    });

    test('default theme mode follows the system', () {
      expect(AppTheme.themeModeDefault, ThemeMode.system);
    });

    test('resolveMode round-trips with encodeMode', () {
      for (final m in ThemeMode.values) {
        expect(AppTheme.resolveMode(AppTheme.encodeMode(m)), m);
      }
    });

    test('resolveMode falls back to system for unknown / null values', () {
      expect(AppTheme.resolveMode(null), ThemeMode.system);
      expect(AppTheme.resolveMode(''), ThemeMode.system);
      expect(AppTheme.resolveMode('purple'), ThemeMode.system);
    });
  });
}
