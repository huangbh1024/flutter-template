import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/mock_sample_repository.dart';
import '../data/sample_repository.dart';
import 'sample_item.dart';

/// 当前使用本地 Mock。接入接口时把这里换成 HttpSampleRepository。
final sampleRepositoryProvider = Provider<SampleRepository>(
  (ref) => MockSampleRepository(),
);

/// 示例列表数据。
///
/// - `autoDispose`：页面销毁后释放，重新进入会重新请求；
/// - 页面用 `ref.watch` 订阅，用 `ref.invalidate` 触发重试 / 刷新。
final sampleItemsProvider = FutureProvider.autoDispose<List<SampleItem>>(
  (ref) => ref.watch(sampleRepositoryProvider).fetchItems(),
);
