import 'package:flutter_app_template/app/app.dart';
import 'package:flutter_app_template/core/config/app_config.dart';
import 'package:flutter_app_template/features/sample/data/mock_sample_repository.dart';
import 'package:flutter_app_template/features/sample/data/sample_repository.dart';
import 'package:flutter_app_template/features/sample/domain/providers.dart';
import 'package:flutter_app_template/features/sample/domain/sample_item.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';

/// 空数据仓库：验证空状态。
class _EmptyRepository implements SampleRepository {
  @override
  Future<List<SampleItem>> fetchItems() async => const <SampleItem>[];
}

/// 始终失败的仓库：验证错误状态。
class _FailingRepository implements SampleRepository {
  @override
  Future<List<SampleItem>> fetchItems() async {
    throw StateError('离线');
  }
}

/// 用零延迟 / 指定仓库启动应用，避免测试里等待真实网络或定时器。
Future<void> _pumpApp(
  WidgetTester tester, {
  SampleRepository? repository,
}) async {
  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        sampleRepositoryProvider.overrideWithValue(
          repository ?? MockSampleRepository(delay: Duration.zero),
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

  testWidgets('空列表展示空状态', (tester) async {
    await _pumpApp(tester, repository: _EmptyRepository());

    expect(find.text('暂无数据'), findsOneWidget);
  });

  testWidgets('加载失败展示错误提示与重试按钮', (tester) async {
    await _pumpApp(tester, repository: _FailingRepository());

    expect(find.textContaining('示例数据加载失败'), findsOneWidget);
    expect(find.text('重试'), findsOneWidget);
  });
}
