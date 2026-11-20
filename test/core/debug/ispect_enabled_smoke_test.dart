import 'package:flutter_app_template/app/app.dart';
import 'package:flutter_app_template/core/config/app_config.dart';
import 'package:flutter_app_template/core/debug/debug_panel.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

/// 只有带 `--dart-define=ISPECT_ENABLED=true` 跑测试时才执行。
///
/// ISpect 的启用开关是编译期常量（`const bool.fromEnvironment`），
/// 无法在运行时 override，所以普通 CI 下这个用例会被跳过；
/// 本地需要验证面板挂载时用：
/// `flutter test --dart-define=ISPECT_ENABLED=true`。
void main() {
  testWidgets(
    '启用调试面板后应用仍可正常构建',
    (tester) async {
      await tester.pumpWidget(const ProviderScope(child: App()));
      // 面板带有常驻动画，不能用 pumpAndSettle。
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));

      expect(tester.takeException(), isNull);
      expect(find.text(AppConfig.appName), findsWidgets);
    },
    // 普通 CI 没有 dart-define 时跳过；本地验证用
    // flutter test --dart-define=ISPECT_ENABLED=true
    skip: !debugPanelEnabled,
  );
}
