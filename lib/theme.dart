import 'package:flutter/material.dart';

/// 主题色选项
const String themeColorBlue = 'blue';
const String themeColorYellow = 'yellow';

/// 根据设置返回主题色（Material 3 ColorScheme 种子色）。
Color themeSeedColor(String themeColor) {
  return switch (themeColor) {
    themeColorYellow => const Color(0xFFF6A821),
    _ => const Color(0xFF2E6BE6),
  };
}

/// 应用主题
ThemeData buildAppTheme(String themeColor) {
  final seed = themeSeedColor(themeColor);
  return ThemeData(
    useMaterial3: true,
    colorScheme: ColorScheme.fromSeed(seedColor: seed),
    scaffoldBackgroundColor: const Color(0xFFF7F8FA),
    appBarTheme: AppBarTheme(
      backgroundColor: const Color(0xFFF7F8FA),
      elevation: 0,
      centerTitle: false,
      titleTextStyle: TextStyle(
        color: Color.alphaBlend(Colors.black, const Color(0xFF2E6BE6)),
        fontSize: 20,
        fontWeight: FontWeight.w600,
      ),
    ),
    cardTheme: const CardThemeData(
      elevation: 0,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.all(Radius.circular(16))),
    ),
    navigationBarTheme: const NavigationBarThemeData(
      elevation: 0,
      labelBehavior: NavigationDestinationLabelBehavior.alwaysShow,
    ),
    snackBarTheme: const SnackBarThemeData(behavior: SnackBarBehavior.floating),
  );
}