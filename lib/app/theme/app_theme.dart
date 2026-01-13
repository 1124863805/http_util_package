import 'package:flutter/material.dart';

/// 应用主题配置
/// 重置所有 Flutter 默认效果，包括水波纹、阴影等
class AppTheme {
  AppTheme._();

  /// 获取应用主题
  static ThemeData get theme {
    return ThemeData(
      useMaterial3: false, // 使用 Material 2，避免 Material 3 的默认效果
      // 禁用水波纹效果
      splashFactory: NoSplash.splashFactory,
      highlightColor: Colors.transparent, // 禁用高亮效果
      splashColor: Colors.transparent, // 禁用水波纹颜色
      // AppBar 主题
      appBarTheme: const AppBarTheme(
        backgroundColor: Colors.blue, // 固定背景色
        foregroundColor: Colors.white, // 固定前景色（文字和图标）
        elevation: 0, // 移除阴影
        scrolledUnderElevation: 0, // 滚动时保持 elevation 为 0
        surfaceTintColor: Colors.transparent, // 移除表面色调
      ),

      // 按钮主题 - 禁用水波纹
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(splashFactory: NoSplash.splashFactory),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(splashFactory: NoSplash.splashFactory),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(splashFactory: NoSplash.splashFactory),
      ),
      iconButtonTheme: IconButtonThemeData(
        style: IconButton.styleFrom(splashFactory: NoSplash.splashFactory),
      ),

      // ListTile 主题
      listTileTheme: const ListTileThemeData(),

      // Card 主题
      cardTheme: const CardThemeData(
        elevation: 0, // 移除阴影
        surfaceTintColor: Colors.transparent, // 移除表面色调
      ),

      // FloatingActionButton 主题 - 禁用水波纹
      floatingActionButtonTheme: const FloatingActionButtonThemeData(
        elevation: 0,
        highlightElevation: 0,
      ),

      // BottomNavigationBar 主题
      bottomNavigationBarTheme: const BottomNavigationBarThemeData(
        elevation: 0,
        backgroundColor: Colors.white,
        selectedItemColor: Colors.blue,
        unselectedItemColor: Colors.grey,
      ),

      // TextField 主题
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: Colors.grey[50],
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: BorderSide(color: Colors.grey[300]!),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: BorderSide(color: Colors.grey[300]!),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: const BorderSide(color: Colors.blue, width: 2),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: const BorderSide(color: Colors.red),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: const BorderSide(color: Colors.red, width: 2),
        ),
      ),

      // Dialog 主题
      dialogTheme: const DialogThemeData(
        elevation: 0,
        surfaceTintColor: Colors.transparent,
      ),

      // BottomSheet 主题
      bottomSheetTheme: const BottomSheetThemeData(
        elevation: 0,
        surfaceTintColor: Colors.transparent,
      ),

      // Drawer 主题
      drawerTheme: const DrawerThemeData(
        elevation: 0,
        surfaceTintColor: Colors.transparent,
      ),

      // Switch 主题
      switchTheme: SwitchThemeData(
        splashRadius: 0,
        overlayColor: WidgetStateProperty.all(Colors.transparent),
      ),

      // Checkbox 主题
      checkboxTheme: CheckboxThemeData(
        splashRadius: 0,
        overlayColor: WidgetStateProperty.all(Colors.transparent),
      ),

      // Radio 主题
      radioTheme: RadioThemeData(
        splashRadius: 0,
        overlayColor: WidgetStateProperty.all(Colors.transparent),
      ),

      // Chip 主题
      chipTheme: const ChipThemeData(elevation: 0, pressElevation: 0),

      // Divider 主题
      dividerTheme: const DividerThemeData(thickness: 1, space: 1),

      // PopupMenuButton 主题
      popupMenuTheme: const PopupMenuThemeData(
        elevation: 0,
        surfaceTintColor: Colors.transparent,
      ),

      // ExpansionTile 主题
      expansionTileTheme: const ExpansionTileThemeData(),

      // DataTable 主题
      dataTableTheme: const DataTableThemeData(),

      // Tooltip 主题
      tooltipTheme: const TooltipThemeData(preferBelow: false),

      // SnackBar 主题
      snackBarTheme: const SnackBarThemeData(
        elevation: 0,
        behavior: SnackBarBehavior.floating,
      ),

      // Slider 主题
      sliderTheme: const SliderThemeData(
        thumbShape: RoundSliderThumbShape(enabledThumbRadius: 6),
      ),

      // ProgressIndicator 主题
      progressIndicatorTheme: const ProgressIndicatorThemeData(),

      // Badge 主题
      badgeTheme: const BadgeThemeData(),

      // NavigationRail 主题
      navigationRailTheme: const NavigationRailThemeData(elevation: 0),
    );
  }
}
