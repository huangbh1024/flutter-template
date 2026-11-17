import 'package:flutter_app_template/features/sample/domain/sample_item.dart';
import 'package:flutter_app_template/features/sample/domain/sample_presenter.dart';
import 'package:flutter_test/flutter_test.dart';

SampleItem _item(String id, DateTime at, {int cents = 100}) {
  return SampleItem(
    id: id,
    title: '条目 $id',
    amountCents: cents,
    occurredAt: at,
  );
}

void main() {
  test('按天倒序分组，并统计当天合计', () {
    final groups = groupByDay([
      _item('a', DateTime(2026, 11, 17, 8), cents: 1000),
      _item('b', DateTime(2026, 11, 17, 16), cents: 2500),
      _item('c', DateTime(2026, 11, 16, 9), cents: 300),
    ]);

    expect(groups, hasLength(2));
    expect(groups.first.day, DateTime(2026, 11, 17));
    // 组内按时间倒序。
    expect(groups.first.items.map((item) => item.id), ['b', 'a']);
    expect(groups.first.totalCents, 3500);
    expect(groups.last.totalCents, 300);
  });

  test('空列表返回空分组', () {
    expect(groupByDay(const <SampleItem>[]), isEmpty);
    expect(totalCentsOf(const <SampleItem>[]), 0);
  });

  test('分组结果不可变，避免页面误改数据', () {
    final groups = groupByDay([_item('a', DateTime(2026, 11, 17))]);
    expect(
      () => groups.first.items.add(_item('b', DateTime(2026, 11, 17))),
      throwsUnsupportedError,
    );
  });
}
