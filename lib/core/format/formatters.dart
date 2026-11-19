import 'package:intl/intl.dart';

/// 全局格式化函数。
///
/// 规则：金额在数据层一律用「整数分」保存，只有在展示层才转成字符串。
/// 日期在数据层保存 UTC 或本地 [DateTime]，展示时统一经由这里格式化。

final NumberFormat _thousands = NumberFormat('#,##0');
final NumberFormat _twoDecimals = NumberFormat('#,##0.00');
final NumberFormat _oneDecimal = NumberFormat('#,##0.0');

/// 聚合金额：千分位、四舍五入取整，例如 `¥1,286`。
String formatYuanCompact(int cents) => '¥${_thousands.format(cents / 100)}';

/// 明细金额：千分位、保留两位，例如 `¥51.10`。
String formatYuanDetail(int cents) => '¥${_twoDecimals.format(cents / 100)}';

/// 概览金额：千分位、保留一位，例如 `¥312.4`。
String formatYuanOneDecimal(int cents) => '¥${_oneDecimal.format(cents / 100)}';

/// 千分位计数，例如 `1,248`。
String formatCount(int value) => _thousands.format(value);

/// 一位小数，例如 `14.8`。
String formatOneDecimal(double value) => value.toStringAsFixed(1);

/// 带符号的百分比，例如 `-8.2%`、`+4.2%`。
String formatSignedPercent(double value) {
  final sign = value > 0 ? '+' : '';
  return '$sign${value.toStringAsFixed(1)}%';
}

/// 把金额拆成「整数部分」与「小数部分」，用于汇总卡的大字排版。
/// 返回的整数部分已带千分位且不含符号，小数部分带小数点（如 `.50`）。
({String integer, String decimal}) splitYuanParts(int cents) {
  final text = _twoDecimals.format(cents.abs() / 100);
  final index = text.lastIndexOf('.');
  return (integer: text.substring(0, index), decimal: text.substring(index));
}

/// 解析用户输入的元金额为整数分。
///
/// 仅接受 `123`、`123.4`、`123.45`；整数 1~6 位、小数 1~2 位。
/// 空串、`.5`、`123.` 这类缺少整数位或小数位的输入返回 null。
int? parseYuanToCents(String raw) {
  final text = raw.trim();
  if (text.isEmpty) {
    return null;
  }
  final match = RegExp(r'^(\d{1,6})(?:\.(\d{1,2}))?$').firstMatch(text);
  if (match == null) {
    return null;
  }
  final yuanText = match.group(1) ?? '';
  final fractionText = (match.group(2) ?? '').padRight(2, '0');
  final yuan = int.tryParse(yuanText.isEmpty ? '0' : yuanText) ?? 0;
  return yuan * 100 + int.parse(fractionText);
}

/// 金额输入框文本：不带千分位、固定两位小数，例如 `1234.56`。
String formatYuanInput(int cents) => (cents / 100).toStringAsFixed(2);

/// 交易时间到分钟，例如 `2026-11-17 13:28`。
String formatDateTimeMinute(DateTime time) {
  final t = time.toLocal();
  String two(int value) => value.toString().padLeft(2, '0');
  return '${t.year}-${two(t.month)}-${two(t.day)} '
      '${two(t.hour)}:${two(t.minute)}';
}

/// 月份标签，例如 `2026年11月`。
String formatMonthLabel(DateTime month) => DateFormat('yyyy年M月').format(month);

/// 日期标签，例如 `2026年11月17日`。
String formatDateLabel(DateTime date) =>
    DateFormat('yyyy年M月d日').format(date);

const _weekdays = ['周一', '周二', '周三', '周四', '周五', '周六', '周日'];

/// 分组日期标题：`今天 · 11月17日` / `11月10日 · 周一` / 跨年带年份。
String formatDayTitle(DateTime day, {DateTime? now}) {
  final n = (now ?? DateTime.now()).toLocal();
  final d = day.toLocal();
  final diff = DateTime(
    n.year,
    n.month,
    n.day,
  ).difference(DateTime(d.year, d.month, d.day)).inDays;
  final base = d.year == n.year
      ? '${d.month}月${d.day}日'
      : '${d.year}年${d.month}月${d.day}日';
  return switch (diff) {
    0 => '今天 · $base',
    1 => '昨天 · $base',
    2 => '前天 · $base',
    _ => '$base · ${_weekdays[d.weekday - 1]}',
  };
}

/// 发生时间的行内文案：`今天 08:42` / `昨天 08:42` / `11月10日 08:42`。
String formatOccurredAtLabel(DateTime time, {DateTime? now}) {
  final n = (now ?? DateTime.now()).toLocal();
  final t = time.toLocal();
  final today = DateTime(n.year, n.month, n.day);
  final day = DateTime(t.year, t.month, t.day);
  final diff = today.difference(day).inDays;
  final hm = '${_two(t.hour)}:${_two(t.minute)}';
  if (diff == 0) {
    return '今天 $hm';
  }
  if (diff == 1) {
    return '昨天 $hm';
  }
  if (t.year == n.year) {
    return '${t.month}月${t.day}日 $hm';
  }
  return '${t.year}年${t.month}月${t.day}日 $hm';
}

String _two(int value) => value.toString().padLeft(2, '0');
