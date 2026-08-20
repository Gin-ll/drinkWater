import 'package:flutter/material.dart';

/// 主题色选项
const String themeColorBlue = 'blue';
const String themeColorGreen = 'green';
const String themeColorYellow = 'yellow';

/// 根据设置返回主题种子色（Material 3 从这里派生整套配色）。
Color themeSeedColor(String themeColor) {
  return switch (themeColor) {
    themeColorGreen => const Color(0xFF34A853), // 清新绿
    themeColorYellow => const Color(0xFFF5A623), // 暖阳黄
    _ => const Color(0xFF3A7BD5), // 清爽蓝
  };
}

/// 应用主题：简约小清新风。
/// - 浅色柔和底色 + 白色圆角卡片 + 轻阴影
/// - 无阴影扁平导航栏 / 半透明 AppBar
ThemeData buildAppTheme(String themeColor) {
  final seed = themeSeedColor(themeColor);
  final scheme = ColorScheme.fromSeed(seedColor: seed);
  return ThemeData(
    useMaterial3: true,
    colorScheme: scheme,
    scaffoldBackgroundColor: const Color(0xFFF6F8F7), // 柔和底色
    appBarTheme: AppBarTheme(
      backgroundColor: const Color(0xFFF6F8F7), // 与底色融合
      elevation: 0,
      scrolledUnderElevation: 0,
      centerTitle: false,
      titleTextStyle: TextStyle(
        color: scheme.onSurface,
        fontSize: 20,
        fontWeight: FontWeight.w700,
      ),
      iconTheme: IconThemeData(color: scheme.onSurfaceVariant),
    ),
    cardTheme: CardThemeData(
      elevation: 0,
      color: Colors.white,
      shadowColor: const Color(0x14000000),
      surfaceTintColor: Colors.transparent,
      margin: const EdgeInsets.symmetric(vertical: 4),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
    ),
    filledButtonTheme: FilledButtonThemeData(
      style: FilledButton.styleFrom(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
        textStyle: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600),
      ),
    ),
    navigationBarTheme: NavigationBarThemeData(
      elevation: 0,
      backgroundColor: Colors.white,
      surfaceTintColor: Colors.transparent,
      height: 64,
      indicatorColor: scheme.secondaryContainer,
      labelBehavior: NavigationDestinationLabelBehavior.alwaysShow,
    ),
    snackBarTheme: const SnackBarThemeData(
      behavior: SnackBarBehavior.floating,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.all(Radius.circular(14))),
    ),
    dividerTheme: const DividerThemeData(color: Color(0xFFEEF1F0), thickness: 1),
  );
}
