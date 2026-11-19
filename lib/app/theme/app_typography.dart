import 'package:material_ui/material_ui.dart';

/// 字体与文本层级。
///
/// 模板不内置字体文件，默认使用系统字体。接入品牌字体时：
/// 1. 在 pubspec.yaml 的 fonts 中声明；
/// 2. 在 [textTheme] 里给样式加 fontFamily。
class AppTypography {
  const AppTypography._();

  /// 中文回退字体，保证数字字体缺失时中文不会出现方框。
  static const _fontFamilyFallback = <String>[
    'PingFang SC',
    'HarmonyOS Sans SC',
    'Noto Sans SC',
    'sans-serif',
  ];

  static const displaySmall = TextStyle(
    fontSize: 32,
    height: 40 / 32,
    fontWeight: FontWeight.w700,
    letterSpacing: -0.5,
  );

  static const headlineSmall = TextStyle(
    fontSize: 22,
    height: 30 / 22,
    fontWeight: FontWeight.w700,
    letterSpacing: -0.3,
  );

  static const titleLarge = TextStyle(
    fontSize: 18,
    height: 24 / 18,
    fontWeight: FontWeight.w700,
  );

  static const titleMedium = TextStyle(
    fontSize: 15,
    height: 22 / 15,
    fontWeight: FontWeight.w600,
  );

  static const bodyLarge = TextStyle(
    fontSize: 15,
    height: 22 / 15,
    fontWeight: FontWeight.w500,
  );

  static const bodyMedium = TextStyle(
    fontSize: 13,
    height: 18 / 13,
    fontWeight: FontWeight.w500,
  );

  static const bodySmall = TextStyle(
    fontSize: 11,
    height: 16 / 11,
    fontWeight: FontWeight.w400,
  );

  static const labelLarge = TextStyle(
    fontSize: 13,
    height: 16 / 13,
    fontWeight: FontWeight.w600,
  );

  static TextTheme textTheme(Color color) {
    TextStyle withColor(TextStyle style) =>
        style.copyWith(color: color, fontFamilyFallback: _fontFamilyFallback);

    return TextTheme(
      displaySmall: withColor(displaySmall),
      headlineSmall: withColor(headlineSmall),
      titleLarge: withColor(titleLarge),
      titleMedium: withColor(titleMedium),
      bodyLarge: withColor(bodyLarge),
      bodyMedium: withColor(bodyMedium),
      bodySmall: withColor(bodySmall),
      labelLarge: withColor(labelLarge),
    );
  }
}
