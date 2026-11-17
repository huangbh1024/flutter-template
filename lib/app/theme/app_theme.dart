import 'package:material_ui/material_ui.dart';

import 'app_colors.dart';
import 'app_tokens.dart';
import 'app_typography.dart';

/// 由语义色 + 布局 token 组装 ThemeData。
///
/// 需要定制组件样式（按钮、输入框、导航栏等）时，在 [_build] 里统一添加
/// 对应组件的 theme，避免在每个页面重复写 style。
class AppTheme {
  const AppTheme._();

  static ThemeData light() => _build(
    brightness: Brightness.light,
    palette: AppPalette.light,
    tokens: AppTokens.light,
  );

  static ThemeData dark() => _build(
    brightness: Brightness.dark,
    palette: AppPalette.dark,
    tokens: AppTokens.dark,
  );

  static ThemeData _build({
    required Brightness brightness,
    required AppPalette palette,
    required AppTokens tokens,
  }) {
    final scheme =
        ColorScheme.fromSeed(
          seedColor: palette.primary,
          brightness: brightness,
        ).copyWith(
          primary: palette.primary,
          onPrimary: palette.onPrimary,
          secondary: palette.secondary,
          surface: palette.surface,
          onSurface: palette.onSurface,
          error: palette.error,
          outline: palette.outline,
          outlineVariant: palette.outlineVariant,
          surfaceContainerLow: palette.surfaceContainer,
        );

    return ThemeData(
      useMaterial3: true,
      brightness: brightness,
      colorScheme: scheme,
      scaffoldBackgroundColor: palette.background,
      textTheme: AppTypography.textTheme(palette.onSurface),
      extensions: <ThemeExtension<dynamic>>[palette, tokens],
    );
  }
}
