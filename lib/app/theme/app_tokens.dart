import 'package:material_ui/material_ui.dart';

/// 间距、圆角、阴影等布局 token，随深浅色切换。
///
/// 页面里不要散落魔法数字，优先引用 `context.tokens.xxx`。
@immutable
class AppTokens extends ThemeExtension<AppTokens> {
  const AppTokens({
    required this.pagePadding,
    required this.gutter,
    required this.spaceXs,
    required this.spaceSm,
    required this.spaceMd,
    required this.spaceLg,
    required this.spaceXl,
    required this.radiusCard,
    required this.radiusPill,
    required this.cardShadow,
  });

  final double pagePadding;
  final double gutter;
  final double spaceXs;
  final double spaceSm;
  final double spaceMd;
  final double spaceLg;
  final double spaceXl;
  final double radiusCard;
  final double radiusPill;
  final List<BoxShadow> cardShadow;

  static const light = AppTokens(
    pagePadding: 16,
    gutter: 12,
    spaceXs: 4,
    spaceSm: 8,
    spaceMd: 12,
    spaceLg: 20,
    spaceXl: 28,
    radiusCard: 16,
    radiusPill: 999,
    cardShadow: [
      BoxShadow(
        color: Color(0x0A0F172A),
        blurRadius: 24,
        offset: Offset(0, 8),
        spreadRadius: -4,
      ),
      BoxShadow(
        color: Color(0x050F172A),
        blurRadius: 6,
        offset: Offset(0, 2),
        spreadRadius: -1,
      ),
    ],
  );

  static const dark = AppTokens(
    pagePadding: 16,
    gutter: 12,
    spaceXs: 4,
    spaceSm: 8,
    spaceMd: 12,
    spaceLg: 20,
    spaceXl: 28,
    radiusCard: 16,
    radiusPill: 999,
    cardShadow: [
      BoxShadow(
        color: Color(0x66000000),
        blurRadius: 24,
        offset: Offset(0, 8),
        spreadRadius: -4,
      ),
    ],
  );

  @override
  AppTokens copyWith() => this;

  @override
  AppTokens lerp(covariant AppTokens? other, double t) {
    if (other == null) {
      return this;
    }
    List<BoxShadow> lerpShadow(List<BoxShadow> a, List<BoxShadow> b) {
      if (a.length != b.length) {
        return t < 0.5 ? a : b;
      }
      return [
        for (var i = 0; i < a.length; i++)
          BoxShadow.lerp(a[i], b[i], t) ?? a[i],
      ];
    }

    return AppTokens(
      pagePadding: _lerpDouble(pagePadding, other.pagePadding, t),
      gutter: _lerpDouble(gutter, other.gutter, t),
      spaceXs: _lerpDouble(spaceXs, other.spaceXs, t),
      spaceSm: _lerpDouble(spaceSm, other.spaceSm, t),
      spaceMd: _lerpDouble(spaceMd, other.spaceMd, t),
      spaceLg: _lerpDouble(spaceLg, other.spaceLg, t),
      spaceXl: _lerpDouble(spaceXl, other.spaceXl, t),
      radiusCard: _lerpDouble(radiusCard, other.radiusCard, t),
      radiusPill: _lerpDouble(radiusPill, other.radiusPill, t),
      cardShadow: lerpShadow(cardShadow, other.cardShadow),
    );
  }

  static double _lerpDouble(double a, double b, double t) => a + (b - a) * t;
}

extension AppTokensContext on BuildContext {
  AppTokens get tokens =>
      Theme.of(this).extension<AppTokens>() ?? AppTokens.light;
}
