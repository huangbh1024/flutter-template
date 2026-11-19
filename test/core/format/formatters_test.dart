import 'package:flutter_app_template/core/format/formatters.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('金额格式化', () {
    test('明细金额带千分位与两位小数', () {
      expect(formatYuanDetail(5110), '¥51.10');
      expect(formatYuanDetail(123456), '¥1,234.56');
    });

    test('聚合金额四舍五入到整元', () {
      expect(formatYuanCompact(128649), '¥1,286');
    });

    test('splitYuanParts 拆分整数与小数部分', () {
      expect(
        splitYuanParts(114850),
        (integer: '1,148', decimal: '.50'),
      );
    });
  });

  group('金额解析', () {
    test('接受整数与一至两位小数', () {
      expect(parseYuanToCents('123'), 12300);
      expect(parseYuanToCents('123.4'), 12340);
      expect(parseYuanToCents('123.45'), 12345);
      expect(parseYuanToCents('0.05'), 5);
    });

    test('空串、非法字符与超过两位小数返回 null', () {
      expect(parseYuanToCents(''), isNull);
      expect(parseYuanToCents('abc'), isNull);
      expect(parseYuanToCents('12.345'), isNull);
      expect(parseYuanToCents('-1'), isNull);
    });

    test('整数位必须存在且不超过 6 位，小数位不能为空', () {
      expect(parseYuanToCents('.5'), isNull);
      expect(parseYuanToCents('123.'), isNull);
      expect(parseYuanToCents('1234567'), isNull);
      expect(parseYuanToCents('999999'), 99999900);
    });
  });

  group('日期文案', () {
    final now = DateTime(2026, 11, 17, 9, 30);

    test('按相对天数输出分组标题', () {
      expect(formatDayTitle(DateTime(2026, 11, 17), now: now), '今天 · 11月17日');
      expect(formatDayTitle(DateTime(2026, 11, 16), now: now), '昨天 · 11月16日');
      expect(formatDayTitle(DateTime(2026, 11, 15), now: now), '前天 · 11月15日');
      expect(formatDayTitle(DateTime(2026, 11, 10), now: now), '11月10日 · 周二');
    });

    test('跨年分组标题带年份', () {
      expect(
        formatDayTitle(DateTime(2025, 12, 31), now: now),
        '2025年12月31日 · 周三',
      );
    });

    test('发生时间行内文案', () {
      expect(
        formatOccurredAtLabel(DateTime(2026, 11, 17, 8, 42), now: now),
        '今天 08:42',
      );
      expect(
        formatOccurredAtLabel(DateTime(2026, 11, 16, 18, 5), now: now),
        '昨天 18:05',
      );
    });
  });
}
