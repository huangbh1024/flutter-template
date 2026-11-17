import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:material_ui/material_ui.dart';

/// 主题模式：跟随系统 / 浅色 / 深色。
///
/// 需要持久化时，在 Notifier 里读写本地存储，并把 build() 的初始值改为
/// 读取到的值（注意保持 build() 同步）。
final themeModeProvider = NotifierProvider<ThemeModeNotifier, ThemeMode>(
  ThemeModeNotifier.new,
);

class ThemeModeNotifier extends Notifier<ThemeMode> {
  @override
  ThemeMode build() => ThemeMode.system;

  /// 在浅色 / 深色之间切换。
  void toggle() {
    state = state == ThemeMode.dark ? ThemeMode.light : ThemeMode.dark;
  }

  void set(ThemeMode mode) {
    if (state != mode) {
      state = mode;
    }
  }
}
