import 'package:flutter/material.dart';

/// Colors shared by the panel and its tools, independent of the host app theme.
class DebugPanelColors {
  DebugPanelColors._();

  static const Color background = Color(0xFF0B0B12);
  static const Color surface = Color(0xFF14141D);
  static const Color surfaceMuted = Color(0xFF1D1D29);
  static const Color border = Color(0xFF272736);
  static const Color text = Color(0xFFE8E8F0);
  static const Color textMuted = Color(0xFF8B8BA3);
  static const Color accent = Color(0xFF8B6CFF);
  static const Color success = Color(0xFF34D399);
  static const Color warning = Color(0xFFFBBF24);
  static const Color danger = Color(0xFFF87171);
  static const Color info = Color(0xFF60A5FA);
  static const Color fab = Color(0xFF14141D);

  static const Color jsonKey = Color(0xFF7DD3FC);
  static const Color jsonString = Color(0xFFA3E635);
  static const Color jsonNumber = Color(0xFFFBBF24);
  static const Color jsonLiteral = Color(0xFFC4B5FD);

  /// GET green, POST purple, PUT/PATCH amber, DELETE red, anything else blue.
  static Color method(String method) {
    switch (method) {
      case 'GET':
        return success;
      case 'POST':
        return accent;
      case 'PUT':
      case 'PATCH':
        return warning;
      case 'DELETE':
        return danger;
      default:
        return info;
    }
  }

  /// 2xx green, 3xx blue, 4xx amber, 5xx and no response red.
  static Color status(int? code) {
    if (code == null || code >= 500) return danger;
    if (code >= 400) return warning;
    if (code >= 300) return info;
    return success;
  }
}

final TextTheme _textTheme = ThemeData(
  useMaterial3: true,
  brightness: Brightness.dark,
).textTheme;

/// The theme the panel and its tools render with.
final ThemeData debugPanelTheme = ThemeData(
  useMaterial3: true,
  brightness: Brightness.dark,
  colorScheme: ColorScheme.fromSeed(
    seedColor: DebugPanelColors.accent,
    brightness: Brightness.dark,
    primary: DebugPanelColors.accent,
    surface: DebugPanelColors.background,
    onSurface: DebugPanelColors.text,
  ),
  scaffoldBackgroundColor: DebugPanelColors.background,
  canvasColor: DebugPanelColors.background,
  dividerColor: DebugPanelColors.border,
  dividerTheme: const DividerThemeData(
    color: DebugPanelColors.border,
    thickness: 1,
    space: 1,
  ),
  appBarTheme: AppBarTheme(
    backgroundColor: DebugPanelColors.background,
    foregroundColor: DebugPanelColors.text,
    surfaceTintColor: Colors.transparent,
    elevation: 0,
    scrolledUnderElevation: 0,
    centerTitle: false,
    titleTextStyle: _textTheme.titleLarge?.copyWith(
      color: DebugPanelColors.text,
      fontSize: 17,
      fontWeight: FontWeight.w700,
    ),
  ),
  snackBarTheme: SnackBarThemeData(
    behavior: SnackBarBehavior.floating,
    elevation: 0,
    insetPadding: const EdgeInsets.fromLTRB(12, 0, 12, 8),
    backgroundColor: DebugPanelColors.surfaceMuted,
    contentTextStyle: _textTheme.bodyMedium?.copyWith(
      color: DebugPanelColors.text,
      fontSize: 13,
    ),
    shape: RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(10),
      side: const BorderSide(color: DebugPanelColors.border),
    ),
  ),
  tabBarTheme: TabBarThemeData(
    labelColor: DebugPanelColors.text,
    unselectedLabelColor: DebugPanelColors.textMuted,
    indicatorColor: DebugPanelColors.accent,
    indicatorSize: TabBarIndicatorSize.label,
    dividerColor: DebugPanelColors.border,
    labelStyle: _textTheme.labelLarge?.copyWith(
      fontSize: 13,
      fontWeight: FontWeight.w600,
    ),
    unselectedLabelStyle: _textTheme.labelLarge?.copyWith(
      fontSize: 13,
      fontWeight: FontWeight.w500,
    ),
    labelPadding: const EdgeInsets.symmetric(horizontal: 12),
    tabAlignment: TabAlignment.start,
  ),
);

/// Monospace text for payloads and values.
const TextStyle debugPanelMonoStyle = TextStyle(
  fontFamily: 'monospace',
  fontFamilyFallback: <String>['Menlo', 'Courier', 'RobotoMono'],
  fontSize: 12,
  height: 1.5,
  color: DebugPanelColors.text,
);
