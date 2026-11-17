import 'package:flutter_app_template/app/app.dart';
import 'package:flutter_app_template/core/config/app_config.dart';
import 'package:flutter_app_template/features/sample/data/mock_sample_repository.dart';
import 'package:flutter_app_template/features/sample/domain/providers.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';

/// 用零延迟的 Mock 仓库启动应用，避免测试里等待真实网络 / 定时器。
Future<void> _pumpApp(WidgetTester tester) async {
  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        sampleRepositoryProvider.overrideWithValue(
          MockSampleRepository(delay: Duration.zero),
        ),
      ],
      child: const App(),
    ),
  );
  await tester.pumpAndSettle();
}

void main() {
  testWidgets('示例页展示 Mock 数据与合计', (tester) async {
    await _pumpApp(tester);

    expect(find.text(AppConfig.appName), findsOneWidget);
    expect(find.textContaining('示例条目 A'), findsOneWidget);
    expect(find.text('合计'), findsOneWidget);
    // 1280 + 3560 + 990 + 24500 = 30330 分。
    expect(find.text('¥303.30'), findsOneWidget);
  });

  testWidgets('主题切换按钮在深浅色间切换', (tester) async {
    await _pumpApp(tester);

    expect(find.byIcon(Icons.dark_mode_rounded), findsOneWidget);
    await tester.tap(find.byIcon(Icons.dark_mode_rounded));
    await tester.pumpAndSettle();
    expect(find.byIcon(Icons.light_mode_rounded), findsOneWidget);
  });
}
