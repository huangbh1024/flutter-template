import 'package:material_ui/material_ui.dart';

/// 示例业务模型。
///
/// 约定：
/// - 领域模型不可变（字段全部 final，构造后不再修改）；
/// - 金额用整数「分」，避免浮点误差；
/// - 时间字段用 [DateTime]，展示时再格式化。
@immutable
class SampleItem {
  const SampleItem({
    required this.id,
    required this.title,
    required this.amountCents,
    required this.occurredAt,
  });

  final String id;
  final String title;
  final int amountCents;
  final DateTime occurredAt;
}
