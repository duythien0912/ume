import 'package:flutter/material.dart';

/// Colors shared by the panel and its tools, independent of the host app theme.
class DebugPanelColors {
  DebugPanelColors._();

  static const Color surface = Color(0xFFFFFFFF);
  static const Color surfaceMuted = Color(0xFFF3F4F6);
  static const Color border = Color(0xFFE5E7EB);
  static const Color text = Color(0xFF111827);
  static const Color textMuted = Color(0xFF6B7280);
  static const Color accent = Color(0xFF4F46E5);
  static const Color success = Color(0xFF16A34A);
  static const Color warning = Color(0xFFD97706);
  static const Color danger = Color(0xFFDC2626);
  static const Color info = Color(0xFF2563EB);
  static const Color fab = Color(0xFF111827);
}

final TextTheme _textTheme = ThemeData(useMaterial3: true).textTheme;

/// The theme the panel and its tools render with.
final ThemeData debugPanelTheme = ThemeData(
  useMaterial3: true,
  colorScheme: ColorScheme.fromSeed(
    seedColor: DebugPanelColors.accent,
    primary: DebugPanelColors.accent,
    surface: DebugPanelColors.surface,
    onSurface: DebugPanelColors.text,
  ),
  scaffoldBackgroundColor: DebugPanelColors.surface,
  dividerColor: DebugPanelColors.border,
  appBarTheme: AppBarTheme(
    backgroundColor: DebugPanelColors.surface,
    foregroundColor: DebugPanelColors.text,
    surfaceTintColor: Colors.transparent,
    elevation: 0,
    scrolledUnderElevation: 0,
    centerTitle: false,
    titleTextStyle: _textTheme.titleLarge?.copyWith(
      color: DebugPanelColors.text,
      fontSize: 18,
      fontWeight: FontWeight.w700,
    ),
  ),
  outlinedButtonTheme: OutlinedButtonThemeData(
    style: OutlinedButton.styleFrom(
      textStyle: _textTheme.labelLarge?.copyWith(
        fontSize: 13,
        fontWeight: FontWeight.w600,
      ),
    ),
  ),
  tabBarTheme: const TabBarThemeData(
    labelColor: DebugPanelColors.accent,
    unselectedLabelColor: DebugPanelColors.textMuted,
    indicatorColor: DebugPanelColors.accent,
    indicatorSize: TabBarIndicatorSize.label,
    dividerColor: DebugPanelColors.border,
    labelStyle: TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
    unselectedLabelStyle: TextStyle(fontSize: 14, fontWeight: FontWeight.w500),
    tabAlignment: TabAlignment.start,
  ),
);

/// Monospace text for payloads and values.
const TextStyle debugPanelMonoStyle = TextStyle(
  fontFamily: 'monospace',
  fontFamilyFallback: <String>['Menlo', 'Courier', 'RobotoMono'],
  fontSize: 12,
  height: 1.45,
  color: DebugPanelColors.text,
);
