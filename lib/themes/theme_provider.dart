import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'themes.dart';

enum AppTheme { light, dark, system }

/// 🌙 ThemeProvider with Islamic aesthetic enhancements
/// Supports: persistence, system theme, callbacks, smooth transitions
class ThemeProvider extends ChangeNotifier {
  static const String _prefKey = 'app_theme_preference';
  static const String _prefUseSystem = 'use_system_theme';

  SharedPreferences? _prefs;
  AppTheme _currentTheme = AppTheme.light; // Default to system
  bool _isLoading = true;

  // Callbacks for external reactions to theme changes
  final List<void Function(AppTheme)> _themeChangeListeners = [];

  // Getters
  AppTheme get currentTheme => _currentTheme;
  bool get isLoading => _isLoading;
  bool get isDarkMode => _resolvedBrightness == Brightness.dark;

  /// Returns the actual brightness being used (resolves system theme)
  Brightness get resolvedBrightness => _resolvedBrightness;

  /// Returns ThemeMode for MaterialApp integration
  ThemeMode get themeMode {
    switch (_currentTheme) {
      case AppTheme.system:
        return ThemeMode.system;
      case AppTheme.dark:
        return ThemeMode.dark;
      case AppTheme.light:
      default:
        return ThemeMode.light;
    }
  }

  /// Cached resolved brightness to avoid repeated calculations
  late Brightness _resolvedBrightness;

  /// Get current ThemeData with Islamic enhancements
  ThemeData get themeData {
    final brightness = _resolvedBrightness;
    return brightness == Brightness.dark
        ? AppThemes.darkTheme
        : AppThemes.lightTheme;
  }

  ThemeProvider() {
    _updateResolvedBrightness();
    _initializeAsync(); // Fire-and-forget with error handling
  }

  /// Async initialization - call this before runApp if you need sync readiness
  static Future<ThemeProvider> createInitialized() async {
    final provider = ThemeProvider._internal();
    await provider._initializeAsync();
    return provider;
  }

  ThemeProvider._internal();

  Future<void> _initializeAsync() async {
    try {
      _prefs = await SharedPreferences.getInstance();
      await _loadTheme();
    } catch (e, stack) {
      debugPrint('❌ ThemeProvider initialization error: $e\n$stack');
      // Fallback gracefully
      _currentTheme = AppTheme.system;
      _updateResolvedBrightness();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Load theme from preferences with validation
  Future<void> _loadTheme() async {
    if (_prefs == null) return;

    // Check if user explicitly chose a theme or prefers system
    final useSystem = _prefs?.getBool(_prefUseSystem) ?? true;

    if (useSystem) {
      _currentTheme = AppTheme.system;
    } else {
      final themeIndex = _prefs?.getInt(_prefKey);
      if (themeIndex != null && themeIndex < AppTheme.values.length - 1) {
        // Exclude 'system' from stored values (only light/dark persisted)
        _currentTheme = AppTheme.values[themeIndex];
      } else {
        _currentTheme = AppTheme.light;
      }
    }

    _updateResolvedBrightness();
  }

  /// Update the actual brightness based on current theme + system settings
  void _updateResolvedBrightness() {
    if (_currentTheme == AppTheme.system) {
      final platformBrightness =
          WidgetsBinding.instance.platformDispatcher.platformBrightness;
      _resolvedBrightness = platformBrightness;
    } else {
      _resolvedBrightness =
          _currentTheme == AppTheme.dark ? Brightness.dark : Brightness.light;
    }
  }

  /// Save theme preference to storage
  Future<void> _saveTheme() async {
    if (_prefs == null) return;

    try {
      // Store whether to use system theme
      await _prefs!.setBool(_prefUseSystem, _currentTheme == AppTheme.system);

      // Only persist explicit choice if not using system
      if (_currentTheme != AppTheme.system) {
        await _prefs!.setInt(_prefKey, _currentTheme.index);
      }
    } catch (e, stack) {
      debugPrint('❌ Error saving theme preference: $e\n$stack');
    }
  }

  /// Change theme with optional callback notification
  Future<void> setTheme(AppTheme theme, {bool notifyExternal = true}) async {
    if (_currentTheme == theme) return;

    _currentTheme = theme;
    _updateResolvedBrightness();

    await _saveTheme();

    notifyListeners();

    if (notifyExternal) {
      for (final callback in _themeChangeListeners) {
        try {
          callback(theme);
        } catch (e) {
          debugPrint('❌ Theme change listener error: $e');
        }
      }
    }
  }

  /// Toggle between light and dark (ignores system mode)
  Future<void> toggleTheme() async {
    final newTheme = isDarkMode ? AppTheme.light : AppTheme.dark;
    await setTheme(newTheme);
  }

  /// Reset to follow system theme
  Future<void> useSystemTheme() async {
    await setTheme(AppTheme.system);
  }

  /// Register a callback for external theme change reactions
  void addThemeChangeListener(void Function(AppTheme) callback) {
    if (!_themeChangeListeners.contains(callback)) {
      _themeChangeListeners.add(callback);
    }
  }

  /// Remove a previously registered callback
  void removeThemeChangeListener(void Function(AppTheme) callback) {
    _themeChangeListeners.remove(callback);
  }

  /// Get theme display name for UI
  String getThemeDisplayName(AppTheme theme) {
    switch (theme) {
      case AppTheme.system:
        return 'Follow System';
      case AppTheme.dark:
        return 'Dark Mode';
      case AppTheme.light:
      default:
        return 'Light Mode';
    }
  }

  /// Get theme icon for UI
  IconData getThemeIcon(AppTheme theme) {
    switch (theme) {
      case AppTheme.system:
        return Icons.brightness_auto;
      case AppTheme.dark:
        return Icons.brightness_4;
      case AppTheme.light:
      default:
        return Icons.brightness_5;
    }
  }

  @override
  void dispose() {
    _themeChangeListeners.clear();
    super.dispose();
  }
}
