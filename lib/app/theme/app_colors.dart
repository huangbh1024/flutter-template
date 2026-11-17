import 'package:material_ui/material_ui.dart';

/// 应用语义色。
///
/// 业务代码不要直接写十六进制颜色，统一从 `context.palette` 或
/// `Theme.of(context).colorScheme` 取值，保证深浅色一致。
@immutable
class AppPalette extends ThemeExtension<AppPalette> {
  const AppPalette({
    required this.background,
    required this.surface,
    required this.surfaceContainer,
    required this.onSurface,
    required this.onSurfaceVariant,
    required this.outline,
    required this.outlineVariant,
    required this.primary,
    required this.onPrimary,
    required this.secondary,
    required this.error,
    required this.errorSoft,
    required this.cardBorder,
    required this.shadow,
  });

  final Color background;
  final Color surface;
  final Color surfaceContainer;
  final Color onSurface;
  final Color onSurfaceVariant;
  final Color outline;
  final Color outlineVariant;
  final Color primary;
  final Color onPrimary;
  final Color secondary;
  final Color error;
  final Color errorSoft;
  final Color cardBorder;
  final Color shadow;

  static const light = AppPalette(
    background: Color(0xFFF7F9FC),
    surface: Colors.white,
    surfaceContainer: Color(0xFFEFF4FB),
    onSurface: Color(0xFF0B1C30),
    onSurfaceVariant: Color(0xFF64748B),
    outline: Color(0xFF94A3B8),
    outlineVariant: Color(0xFFDCE6F2),
    primary: Color(0xFF2563EB),
    onPrimary: Colors.white,
    secondary: Color(0xFFF59E0B),
    error: Color(0xFFBA1A1A),
    errorSoft: Color(0xFFFEE2E2),
    cardBorder: Color(0xFFE6EDF7),
    shadow: Color(0xFF0F172A),
  );

  /// TODO(design): 深色值接入正式设计稿后替换。
  static const dark = AppPalette(
    background: Color(0xFF0B1220),
    surface: Color(0xFF14203A),
    surfaceContainer: Color(0xFF1C2C4A),
    onSurface: Color(0xFFEAF1FF),
    onSurfaceVariant: Color(0xFFA8BCD4),
    outline: Color(0xFF7E8FA6),
    outlineVariant: Color(0xFF2A405C),
    primary: Color(0xFF60A5FA),
    onPrimary: Color(0xFF06182F),
    secondary: Color(0xFFFBBF24),
    error: Color(0xFFFFB4AB),
    errorSoft: Color(0xFF4A1D1D),
    cardBorder: Color(0x1AFFFFFF),
    shadow: Color(0xFF000000),
  );

  @override
  AppPalette copyWith() => this;

  @override
  AppPalette lerp(covariant AppPalette? other, double t) {
    if (other == null) {
      return this;
    }
    return AppPalette(
      background: Color.lerp(background, other.background, t)!,
      surface: Color.lerp(surface, other.surface, t)!,
      surfaceContainer: Color.lerp(
        surfaceContainer,
        other.surfaceContainer,
        t,
      )!,
      onSurface: Color.lerp(onSurface, other.onSurface, t)!,
      onSurfaceVariant: Color.lerp(
        onSurfaceVariant,
        other.onSurfaceVariant,
        t,
      )!,
      outline: Color.lerp(outline, other.outline, t)!,
      outlineVariant: Color.lerp(outlineVariant, other.outlineVariant, t)!,
      primary: Color.lerp(primary, other.primary, t)!,
      onPrimary: Color.lerp(onPrimary, other.onPrimary, t)!,
      secondary: Color.lerp(secondary, other.secondary, t)!,
      error: Color.lerp(error, other.error, t)!,
      errorSoft: Color.lerp(errorSoft, other.errorSoft, t)!,
      cardBorder: Color.lerp(cardBorder, other.cardBorder, t)!,
      shadow: Color.lerp(shadow, other.shadow, t)!,
    );
  }
}

extension AppPaletteContext on BuildContext {
  AppPalette get palette =>
      Theme.of(this).extension<AppPalette>() ?? AppPalette.light;
}
