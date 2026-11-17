import 'package:material_ui/material_ui.dart';

import 'sample_item.dart';

/// 按天分组后的列表单元。
@immutable
class SampleDayGroup {
  const SampleDayGroup({
    required this.day,
    required this.items,
    required this.totalCents,
  });

  final DateTime day;
  final List<SampleItem> items;
  final int totalCents;
}

/// 合计金额（分）。
int totalCentsOf(Iterable<SampleItem> items) =>
    items.fold(0, (sum, item) => sum + item.amountCents);

/// 按本地日期倒序分组，组内按时间倒序。
///
/// 这类纯函数放在 domain 层，不依赖 Widget，可以直接写普通单测；
/// 页面只负责渲染分组结果。
List<SampleDayGroup> groupByDay(Iterable<SampleItem> items) {
  final buckets = <DateTime, List<SampleItem>>{};
  for (final item in items) {
    final local = item.occurredAt.toLocal();
    final day = DateTime(local.year, local.month, local.day);
    buckets.putIfAbsent(day, () => <SampleItem>[]).add(item);
  }

  final days = buckets.keys.toList()..sort((a, b) => b.compareTo(a));
  return [
    for (final day in days)
      SampleDayGroup(
        day: day,
        items: List<SampleItem>.unmodifiable(
          buckets[day]!..sort((a, b) => b.occurredAt.compareTo(a.occurredAt)),
        ),
        totalCents: totalCentsOf(buckets[day]!),
      ),
  ];
}
