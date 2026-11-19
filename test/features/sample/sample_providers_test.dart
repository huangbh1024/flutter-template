import 'package:flutter_app_template/features/sample/data/mock_sample_repository.dart';
import 'package:flutter_app_template/features/sample/data/sample_repository.dart';
import 'package:flutter_app_template/features/sample/domain/providers.dart';
import 'package:flutter_app_template/features/sample/domain/sample_item.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

/// 抛出 [StateError]（Error，不是 Exception），Riverpod 不会自动重试。
class _FailingRepository implements SampleRepository {
  @override
  Future<List<SampleItem>> fetchItems() async {
    throw StateError('离线');
  }
}

void main() {
  test('sampleItemsProvider 通过注入的仓库取数', () async {
    final container = ProviderContainer.test(
      overrides: [
        sampleRepositoryProvider.overrideWithValue(
          MockSampleRepository(delay: Duration.zero),
        ),
      ],
    );

    final items = await container.read(sampleItemsProvider.future);

    expect(items, hasLength(4));
    expect(items.first.title, contains('示例条目 A'));
  });

  test('仓库异常会进入 error 状态', () async {
    final container = ProviderContainer.test(
      overrides: [
        sampleRepositoryProvider.overrideWithValue(_FailingRepository()),
      ],
    );
    // autoDispose 的 provider 需要有监听者，否则结束后会被立即释放。
    final subscription = container.listen(sampleItemsProvider, (_, _) {});

    await expectLater(
      container.read(sampleItemsProvider.future),
      throwsA(anything),
    );
    expect(container.read(sampleItemsProvider).hasError, isTrue);

    subscription.close();
  });
}
