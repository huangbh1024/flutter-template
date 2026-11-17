import '../domain/sample_item.dart';
import 'sample_repository.dart';

/// 本地 Mock 实现：离线开发与测试使用，不依赖网络。
class MockSampleRepository implements SampleRepository {
  MockSampleRepository({this.delay = const Duration(milliseconds: 300)});

  /// 模拟网络延迟；测试里传 [Duration.zero] 让 `pumpAndSettle` 立即结束。
  final Duration delay;

  @override
  Future<List<SampleItem>> fetchItems() async {
    if (delay > Duration.zero) {
      await Future<void>.delayed(delay);
    }
    final now = DateTime.now();
    return List<SampleItem>.unmodifiable([
      SampleItem(
        id: 'sample-1',
        title: '示例条目 A · 数据来自 Mock 仓库',
        amountCents: 1280,
        occurredAt: now.subtract(const Duration(hours: 2)),
      ),
      SampleItem(
        id: 'sample-2',
        title: '示例条目 B · 接入接口后替换实现',
        amountCents: 3560,
        occurredAt: now.subtract(const Duration(hours: 5)),
      ),
      SampleItem(
        id: 'sample-3',
        title: '示例条目 C · 页面无需改动',
        amountCents: 990,
        occurredAt: now.subtract(const Duration(days: 1, hours: 3)),
      ),
      SampleItem(
        id: 'sample-4',
        title: '示例条目 D · 金额统一用整数分',
        amountCents: 24500,
        occurredAt: now.subtract(const Duration(days: 2)),
      ),
    ]);
  }
}
