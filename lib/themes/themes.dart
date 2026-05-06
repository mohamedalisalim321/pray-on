import 'package:flutter/material.dart';
import 'app_constants.dart';

/// AppTheme provides light and dark theme configurations with Material 3 support
/// Generated with Flutter Theme Generator - Clean, modular, and maintainable
///
/// Features:
/// ✅ Uses AppConstants for consistent design tokens
/// ✅ Modular structure with separate theme components
/// ✅ Material 3 compliant color schemes
/// ✅ Support for 6 contrast modes (light, dark, medium/high contrast variants)
/// ✅ Production-ready with proper type declarations
class AppThemes {
  AppThemes._(); // Private constructor to prevent instantiation

  // ═══════════════════════════════════════════════════════════════════════════════
  // 🎨 PUBLIC THEME GETTERS
  // ═══════════════════════════════════════════════════════════════════════════════

  /// Light theme configuration
  static ThemeData get lightTheme => theme(lightScheme());

  /// Dark theme configuration
  static ThemeData get darkTheme => theme(darkScheme());

  /// Light medium contrast theme
  static ThemeData get lightMediumContrast =>
      theme(lightMediumContrastScheme());

  /// Light high contrast theme
  static ThemeData get lightHighContrast => theme(lightHighContrastScheme());

  /// Dark medium contrast theme
  static ThemeData get darkMediumContrast => theme(darkMediumContrastScheme());

  /// Dark high contrast theme
  static ThemeData get darkHighContrast => theme(darkHighContrastScheme());

  // ═══════════════════════════════════════════════════════════════════════════════
  // 🌈 COLOR SCHEMES - Material 3 compliant
  // ═══════════════════════════════════════════════════════════════════════════════

  /// Light color scheme
  static ColorScheme lightScheme() {
    return const ColorScheme(
      brightness: Brightness.light,
      primary: Color(0xFFf5fff3),
      surfaceTint: Color(0xFFf5fff3),
      onPrimary: Color(0xFF000000),
      primaryContainer: Color(0xFFf5fff2),
      onPrimaryContainer: Color(0xFF013400),
      secondary: Color(0xFFfbfdfb),
      onSecondary: Color(0xFF1f1f1f),
      secondaryContainer: Color(0xFFfafdf9),
      onSecondaryContainer: Color(0xFF193215),
      tertiary: Color(0xFFf5fff2),
      onTertiary: Color(0xFF000000),
      tertiaryContainer: Color(0xFFf5fff2),
      onTertiaryContainer: Color(0xFF023400),
      error: Color(0xFFfffcfc),
      onError: Color(0xFF575757),
      errorContainer: Color(0xFFfffcfb),
      onErrorContainer: Color(0xFF610007),
      surface: Color(0xFFfffbfe),
      onSurface: Color(0xFF1C1B1F),
      onSurfaceVariant: Color(0xFF2e2b32),
      outline: Color(0xFFfcfcfc),
      outlineVariant: Color(0xFFfcfcfc),
      shadow: Color(0xFF000000),
      scrim: Color(0xFF000000),
      inverseSurface: Color(0xFF313033),
      onInverseSurface: Color(0xFFfdfcfd),
      inversePrimary: Color(0xFFf5fff3),
      primaryFixed: Color(0xFFf5fff2),
      onPrimaryFixed: Color(0xFF003400),
      primaryFixedDim: Color(0xFFf5fff2),
      onPrimaryFixedVariant: Color(0xFF073400),
      secondaryFixed: Color(0xFFfafdf9),
      onSecondaryFixed: Color(0xFF14330e),
      secondaryFixedDim: Color(0xFFfafdf9),
      onSecondaryFixedVariant: Color(0xFF1c3119),
      tertiaryFixed: Color(0xFFf5fff2),
      onTertiaryFixed: Color(0xFF003400),
      tertiaryFixedDim: Color(0xFFf5fff2),
      onTertiaryFixedVariant: Color(0xFF073400),
      surfaceDim: Color(0xFFfcfcfd),
      surfaceBright: Color(0xFFfffbfe),
      surfaceContainerLowest: Color(0xFFfcfcfc),
      surfaceContainerLow: Color(0xFFfdfcfe),
      surfaceContainer: Color(0xFFfdfcfe),
      surfaceContainerHigh: Color(0xFFfdfcfd),
      surfaceContainerHighest: Color(0xFFfcfcfd),
    );
  }

  /// Dark color scheme
  static ColorScheme darkScheme() {
    return const ColorScheme(
      brightness: Brightness.dark,
      primary: Color(0xFF18bd00),
      surfaceTint: Color(0xFF18bd00),
      onPrimary: Color(0xFF000000),
      primaryContainer: Color(0xFF009500),
      onPrimaryContainer: Color(0xFF000000),
      secondary: Color(0xFF497f40),
      onSecondary: Color(0xFFFFFFFF),
      secondaryContainer: Color(0xFF215718),
      onSecondaryContainer: Color(0xFFFFFFFF),
      tertiary: Color(0xFF1cde00),
      onTertiary: Color(0xFF000000),
      tertiaryContainer: Color(0xFF00b600),
      onTertiaryContainer: Color(0xFF000000),
      error: Color(0xFFFFB4AB),
      onError: Color(0xFF000000),
      errorContainer: Color(0xFF93000A),
      onErrorContainer: Color(0xFFFFFFFF),
      surface: Color(0xFF10090D),
      onSurface: Color(0xFFE6E0E9),
      onSurfaceVariant: Color(0xFFCAC4D0),
      outline: Color(0xFF938F99),
      outlineVariant: Color(0xFF49454F),
      shadow: Color(0xFF000000),
      scrim: Color(0xFF000000),
      inverseSurface: Color(0xFFE6E0E9),
      onInverseSurface: Color(0xFF313033),
      inversePrimary: Color(0xFF2CD105),
      primaryFixed: Color(0xFF7cff55),
      onPrimaryFixed: Color(0xFF009500),
      primaryFixedDim: Color(0xFF68ff41),
      onPrimaryFixedVariant: Color(0xFF18bd00),
      secondaryFixed: Color(0xFFade3a4),
      onSecondaryFixed: Color(0xFF215718),
      secondaryFixedDim: Color(0xFF99cf90),
      onSecondaryFixedVariant: Color(0xFF497f40),
      tertiaryFixed: Color(0xFF80ff52),
      onTertiaryFixed: Color(0xFF00b600),
      tertiaryFixedDim: Color(0xFF6cff3e),
      onTertiaryFixedVariant: Color(0xFF1cde00),
      surfaceDim: Color(0xFF10090D),
      surfaceBright: Color(0xFF362F33),
      surfaceContainerLowest: Color(0xFF0B0509),
      surfaceContainerLow: Color(0xFF1D1418),
      surfaceContainer: Color(0xFF211A1E),
      surfaceContainerHigh: Color(0xFF2B2329),
      surfaceContainerHighest: Color(0xFF362F33),
    );
  }

  /// Light medium contrast color scheme
  static ColorScheme lightMediumContrastScheme() {
    return lightScheme().copyWith(
      primary: const Color(0xFFe6f0e4),
      surface: const Color(0xFFfaf6f9),
    );
  }

  /// Light high contrast color scheme
  static ColorScheme lightHighContrastScheme() {
    return lightScheme().copyWith(
      primary: const Color(0xFFd7e1d5),
      surface: const Color(0xFFf5f1f4),
      outline: const Color(0xff000000),
    );
  }

  /// Dark medium contrast color scheme
  static ColorScheme darkMediumContrastScheme() {
    return darkScheme().copyWith(
      primary: const Color(0xFF27cc0f),
      surface: const Color(0xFF150e12),
    );
  }

  /// Dark high contrast color scheme
  static ColorScheme darkHighContrastScheme() {
    return darkScheme().copyWith(
      primary: const Color(0xFF36db1e),
      surface: const Color(0xFF1a1317),
      outline: const Color(0xffffffff),
    );
  }

  // ═══════════════════════════════════════════════════════════════════════════════
  // 🎯 MAIN THEME BUILDER - Clean and modular structure
  // ═══════════════════════════════════════════════════════════════════════════════

  /// Main theme function that combines all theme components
  /// Uses clean, modular structure with proper AppConstants integration
  static ThemeData theme(ColorScheme colorScheme) => ThemeData(
        useMaterial3: true,
        brightness: colorScheme.brightness,
        colorScheme: colorScheme,
        textTheme: _textTheme,
        appBarTheme: colorScheme.brightness == Brightness.light
            ? _lightAppBarTheme
            : _darkAppBarTheme,
        elevatedButtonTheme: elevatedButtonTheme(colorScheme),
        filledButtonTheme: filledButtonTheme(colorScheme),
        textButtonTheme: textButtonTheme(colorScheme),
        outlinedButtonTheme: outlinedButtonTheme(colorScheme),
        iconButtonTheme: iconButtonTheme(colorScheme),
        inputDecorationTheme: _inputDecorationTheme,
        cardTheme: _cardTheme,
        chipTheme: _chipTheme,
        progressIndicatorTheme: _progressIndicatorTheme,
        dividerTheme: _dividerTheme,
        bottomNavigationBarTheme: _bottomNavigationBarTheme,
        tabBarTheme: _tabBarTheme,
        switchTheme: switchTheme(colorScheme),
        checkboxTheme: _checkboxTheme,
        radioTheme: _radioTheme,
        sliderTheme: _sliderTheme,
        scaffoldBackgroundColor: colorScheme.surface,
        canvasColor: colorScheme.surface,
      );

  // ═══════════════════════════════════════════════════════════════════════════════
  // 🎨 THEME COMPONENTS - All using AppConstants for consistency
  // ═══════════════════════════════════════════════════════════════════════════════

  /// Text theme using AppConstants for consistent font sizes
  static final TextTheme _textTheme = TextTheme(
    displayLarge: TextStyle(
      fontSize: AppConstants.fontSizeDisplayLarge,
      fontWeight: FontWeight.w400,
      letterSpacing: -0.25,
      height: 1.12,
    ),
    displayMedium: TextStyle(
      fontSize: AppConstants.fontSizeDisplayMedium,
      fontWeight: FontWeight.w400,
      letterSpacing: 0,
      height: 1.16,
    ),
    displaySmall: TextStyle(
      fontSize: AppConstants.fontSizeDisplaySmall,
      fontWeight: FontWeight.w400,
      letterSpacing: 0,
      height: 1.22,
    ),
    headlineLarge: TextStyle(
      fontSize: AppConstants.fontSizeHeadlineLarge,
      fontWeight: FontWeight.w400,
      letterSpacing: 0,
      height: 1.25,
    ),
    headlineMedium: TextStyle(
      fontSize: AppConstants.fontSizeHeadlineMedium,
      fontWeight: FontWeight.w400,
      letterSpacing: 0,
      height: 1.29,
    ),
    headlineSmall: TextStyle(
      fontSize: AppConstants.fontSizeHeadlineSmall,
      fontWeight: FontWeight.w400,
      letterSpacing: 0,
      height: 1.33,
    ),
    titleLarge: TextStyle(
      fontSize: AppConstants.fontSizeTitleLarge,
      fontWeight: FontWeight.w400,
      letterSpacing: 0,
      height: 1.27,
    ),
    titleMedium: TextStyle(
      fontSize: AppConstants.fontSizeTitleMedium,
      fontWeight: FontWeight.w500,
      letterSpacing: 0.15,
      height: 1.50,
    ),
    titleSmall: TextStyle(
      fontSize: AppConstants.fontSizeTitleSmall,
      fontWeight: FontWeight.w500,
      letterSpacing: 0.1,
      height: 1.43,
    ),
    labelLarge: TextStyle(
      fontSize: AppConstants.fontSizeLabelLarge,
      fontWeight: FontWeight.w500,
      letterSpacing: 0.1,
      height: 1.43,
    ),
    labelMedium: TextStyle(
      fontSize: AppConstants.fontSizeLabelMedium,
      fontWeight: FontWeight.w500,
      letterSpacing: 0.5,
      height: 1.33,
    ),
    labelSmall: TextStyle(
      fontSize: AppConstants.fontSizeLabelSmall,
      fontWeight: FontWeight.w500,
      letterSpacing: 0.5,
      height: 1.45,
    ),
    bodyLarge: TextStyle(
      fontSize: AppConstants.fontSizeBodyLarge,
      fontWeight: FontWeight.w400,
      letterSpacing: 0.15,
      height: 1.50,
    ),
    bodyMedium: TextStyle(
      fontSize: AppConstants.fontSizeBodyMedium,
      fontWeight: FontWeight.w400,
      letterSpacing: 0.25,
      height: 1.43,
    ),
    bodySmall: TextStyle(
      fontSize: AppConstants.fontSizeBodySmall,
      fontWeight: FontWeight.w400,
      letterSpacing: 0.4,
      height: 1.33,
    ),
  );

  /// Elevated button theme - M3 compliant with WidgetStateProperty
  static ElevatedButtonThemeData elevatedButtonTheme(ColorScheme colorScheme) =>
      ElevatedButtonThemeData(
        style: ButtonStyle(
          elevation: WidgetStateProperty.resolveWith((states) {
            if (states.contains(WidgetState.disabled)) return 0;
            if (states.contains(WidgetState.hovered)) {
              return AppConstants.elevationLevel3;
            }
            if (states.contains(WidgetState.pressed)) {
              return AppConstants.elevationLevel1;
            }
            return AppConstants.elevationLevel2;
          }),
          padding: WidgetStateProperty.all(
            EdgeInsets.symmetric(
              horizontal: AppConstants.spacingLG,
              vertical: AppConstants.spacingMD,
            ),
          ),
          shape: WidgetStateProperty.all(
            RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(AppConstants.radiusMD),
            ),
          ),
          backgroundColor: WidgetStateProperty.resolveWith((states) {
            if (states.contains(WidgetState.disabled)) {
              return colorScheme.onSurface.withOpacity(0.12);
            }
            return colorScheme.primary;
          }),
          foregroundColor: WidgetStateProperty.resolveWith((states) {
            if (states.contains(WidgetState.disabled)) {
              return colorScheme.onSurface.withOpacity(0.38);
            }
            return colorScheme.onPrimary;
          }),
          overlayColor: WidgetStateProperty.resolveWith((states) {
            if (states.contains(WidgetState.pressed)) {
              return colorScheme.onPrimary.withOpacity(0.1);
            }
            if (states.contains(WidgetState.hovered)) {
              return colorScheme.onPrimary.withOpacity(0.08);
            }
            if (states.contains(WidgetState.focused)) {
              return colorScheme.onPrimary.withOpacity(0.1);
            }
            return null;
          }),
          shadowColor: WidgetStateProperty.all(colorScheme.shadow),
        ),
      );

  /// Filled button theme - M3 compliant with WidgetStateProperty
  static FilledButtonThemeData filledButtonTheme(ColorScheme colorScheme) =>
      FilledButtonThemeData(
        style: ButtonStyle(
          padding: WidgetStateProperty.all(
            EdgeInsets.symmetric(
              horizontal: AppConstants.spacingLG,
              vertical: AppConstants.spacingMD,
            ),
          ),
          shape: WidgetStateProperty.all(
            RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(AppConstants.radiusMD),
            ),
          ),
          backgroundColor: WidgetStateProperty.resolveWith((states) {
            if (states.contains(WidgetState.disabled)) {
              return colorScheme.onSurface.withOpacity(0.12);
            }
            return colorScheme.secondaryContainer;
          }),
          foregroundColor: WidgetStateProperty.resolveWith((states) {
            if (states.contains(WidgetState.disabled)) {
              return colorScheme.onSurface.withOpacity(0.38);
            }
            return colorScheme.onSecondaryContainer;
          }),
          overlayColor: WidgetStateProperty.resolveWith((states) {
            if (states.contains(WidgetState.pressed)) {
              return colorScheme.onSecondaryContainer.withOpacity(0.1);
            }
            if (states.contains(WidgetState.hovered)) {
              return colorScheme.onSecondaryContainer.withOpacity(0.08);
            }
            return null;
          }),
        ),
      );

  /// Text button theme - M3 compliant with WidgetStateProperty
  static TextButtonThemeData textButtonTheme(ColorScheme colorScheme) =>
      TextButtonThemeData(
        style: ButtonStyle(
          padding: WidgetStateProperty.all(
            EdgeInsets.symmetric(
              horizontal: AppConstants.spacingLG,
              vertical: AppConstants.spacingMD,
            ),
          ),
          shape: WidgetStateProperty.all(
            RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(AppConstants.radiusMD),
            ),
          ),
          foregroundColor: WidgetStateProperty.resolveWith((states) {
            if (states.contains(WidgetState.disabled)) {
              return colorScheme.onSurface.withOpacity(0.38);
            }
            return colorScheme.primary;
          }),
          overlayColor: WidgetStateProperty.resolveWith((states) {
            if (states.contains(WidgetState.pressed)) {
              return colorScheme.primary.withOpacity(0.1);
            }
            if (states.contains(WidgetState.hovered)) {
              return colorScheme.primary.withOpacity(0.08);
            }
            if (states.contains(WidgetState.focused)) {
              return colorScheme.primary.withOpacity(0.1);
            }
            return null;
          }),
        ),
      );

  /// Outlined button theme - M3 compliant with WidgetStateProperty
  static OutlinedButtonThemeData outlinedButtonTheme(ColorScheme colorScheme) =>
      OutlinedButtonThemeData(
        style: ButtonStyle(
          padding: WidgetStateProperty.all(
            EdgeInsets.symmetric(
              horizontal: AppConstants.spacingLG,
              vertical: AppConstants.spacingMD,
            ),
          ),
          shape: WidgetStateProperty.all(
            RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(AppConstants.radiusMD),
            ),
          ),
          side: WidgetStateProperty.resolveWith((states) {
            if (states.contains(WidgetState.disabled)) {
              return BorderSide(color: colorScheme.onSurface.withOpacity(0.12));
            }
            if (states.contains(WidgetState.focused)) {
              return BorderSide(color: colorScheme.primary);
            }
            return BorderSide(color: colorScheme.outline);
          }),
          foregroundColor: WidgetStateProperty.resolveWith((states) {
            if (states.contains(WidgetState.disabled)) {
              return colorScheme.onSurface.withOpacity(0.38);
            }
            return colorScheme.primary;
          }),
          overlayColor: WidgetStateProperty.resolveWith((states) {
            if (states.contains(WidgetState.pressed)) {
              return colorScheme.primary.withOpacity(0.1);
            }
            if (states.contains(WidgetState.hovered)) {
              return colorScheme.primary.withOpacity(0.08);
            }
            return null;
          }),
        ),
      );

  /// Icon button theme - M3 compliant with WidgetStateProperty
  static IconButtonThemeData iconButtonTheme(ColorScheme colorScheme) =>
      IconButtonThemeData(
        style: ButtonStyle(
          foregroundColor: WidgetStateProperty.resolveWith((states) {
            if (states.contains(WidgetState.disabled)) {
              return colorScheme.onSurface.withOpacity(0.38);
            }
            return colorScheme.onSurfaceVariant;
          }),
          overlayColor: WidgetStateProperty.resolveWith((states) {
            if (states.contains(WidgetState.pressed)) {
              return colorScheme.onSurfaceVariant.withOpacity(0.1);
            }
            if (states.contains(WidgetState.hovered)) {
              return colorScheme.onSurfaceVariant.withOpacity(0.08);
            }
            return null;
          }),
        ),
      );

  /// Input decoration theme
  static final InputDecorationTheme _inputDecorationTheme =
      InputDecorationTheme(
    contentPadding: EdgeInsets.symmetric(
      horizontal: AppConstants.spacingMD,
      vertical: AppConstants.spacingMD,
    ),
    border: OutlineInputBorder(
      borderRadius: BorderRadius.circular(AppConstants.radiusMD),
    ),
    enabledBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(AppConstants.radiusMD),
    ),
    focusedBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(AppConstants.radiusMD),
    ),
    errorBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(AppConstants.radiusMD),
    ),
  );

  /// App bar theme for light mode
  static final AppBarTheme _lightAppBarTheme = AppBarTheme(
    elevation: AppConstants.elevationLevel1,
    centerTitle: false,
    titleSpacing: AppConstants.spacingMD,
    scrolledUnderElevation: AppConstants.elevationLevel1,
  );

  /// App bar theme for dark mode
  static final AppBarTheme _darkAppBarTheme = AppBarTheme(
    elevation: AppConstants.elevationLevel1,
    centerTitle: false,
    titleSpacing: AppConstants.spacingMD,
    scrolledUnderElevation: AppConstants.elevationLevel1,
  );

  /// Card theme
  static final CardTheme _cardTheme = CardTheme(
    elevation: AppConstants.elevationLevel1,
    margin: EdgeInsets.all(AppConstants.spacingSM),
    shape: RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(AppConstants.radiusLG),
    ),
  );

  /// Chip theme
  static final ChipThemeData _chipTheme = ChipThemeData(
    padding: EdgeInsets.symmetric(
      horizontal: AppConstants.spacingMD,
      vertical: AppConstants.spacingSM,
    ),
    shape: RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(AppConstants.radiusFull),
    ),
  );

  /// Progress indicator theme
  static const ProgressIndicatorThemeData _progressIndicatorTheme =
      ProgressIndicatorThemeData();

  /// Divider theme
  static final DividerThemeData _dividerTheme = DividerThemeData(
    thickness: AppConstants.borderWidthThin,
    space: AppConstants.spacingMD,
  );

  /// Bottom navigation bar theme
  static const BottomNavigationBarThemeData _bottomNavigationBarTheme =
      BottomNavigationBarThemeData(
    type: BottomNavigationBarType.fixed,
  );

  /// Tab bar theme
  static final TabBarTheme _tabBarTheme = TabBarTheme(
    labelPadding: EdgeInsets.symmetric(
      horizontal: AppConstants.spacingMD,
      vertical: AppConstants.spacingSM,
    ),
  );

  /// Switch theme - uses colorScheme from theme() parameter
  static SwitchThemeData switchTheme(ColorScheme colorScheme) =>
      SwitchThemeData(
        thumbColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return colorScheme.primary;
          }
          return null;
        }),
        trackColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return colorScheme.primaryContainer;
          }
          return null;
        }),
      );

  /// Checkbox theme
  static final CheckboxThemeData _checkboxTheme = CheckboxThemeData(
    shape: RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(AppConstants.radiusXS),
    ),
  );

  /// Radio theme
  static const RadioThemeData _radioTheme = RadioThemeData();

  /// Slider theme
  static const SliderThemeData _sliderTheme = SliderThemeData();
}

/// Custom theme colors extension for additional brand colors
extension CustomColors on ColorScheme {
  /// Success color for positive actions and states
  Color get success => const Color(0xFFfafdfa);

  /// Warning color for caution states
  Color get warning => const Color(0xFFfffcf8);

  /// Info color for informational states
  Color get info => const Color(0xFFfbfdff);
}
