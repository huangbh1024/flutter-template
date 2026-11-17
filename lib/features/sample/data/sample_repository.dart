import '../domain/sample_item.dart';

/// 示例数据仓库接口。
///
/// UI 与 provider 只依赖这个抽象；接入后端时新增
/// `HttpSampleRepository implements SampleRepository`，
/// 然后修改 `providers.dart` 中的实现即可，页面无需改动。
abstract class SampleRepository {
  Future<List<SampleItem>> fetchItems();
}
