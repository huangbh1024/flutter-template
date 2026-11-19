import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:material_ui/material_ui.dart';

import '../../../app/theme/app_colors.dart';
import '../../../app/theme/app_tokens.dart';
import '../../../core/format/formatters.dart';
import '../../../core/widgets/app_card.dart';
import '../../../core/widgets/empty_state.dart';
import '../../../core/widgets/section_error.dart';
import '../domain/providers.dart';
import '../domain/sample_item.dart';
import '../domain/sample_presenter.dart';
import 'widgets/sample_row.dart';

/// 示例页面：演示「加载 / 失败 / 空 / 有数据」四种状态与下拉刷新。
///
/// 页面只依赖 providers，不直接依赖数据实现；换成真实接口时无需改这里。
class SamplePage extends ConsumerWidget {
  const SamplePage({super.key});

  Future<void> _refresh(WidgetRef ref) async {
    ref.invalidate(sampleItemsProvider);
    try {
      await ref.read(sampleItemsProvider.future);
    } catch (error) {
      // 失败态由下面的 error 分支呈现，这里只需结束下拉动画。
      debugPrint('刷新示例数据失败：$error');
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final itemsAsync = ref.watch(sampleItemsProvider);
    return RefreshIndicator(
      onRefresh: () => _refresh(ref),
      child: itemsAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, stackTrace) => ListView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: EdgeInsets.all(context.tokens.pagePadding),
          children: [
            SectionError(
              message: '示例数据加载失败：$error',
              onRetry: () => ref.invalidate(sampleItemsProvider),
            ),
          ],
        ),
        data: (items) => _SampleList(items: items),
      ),
    );
  }
}

class _SampleList extends StatelessWidget {
  const _SampleList({required this.items});

  final List<SampleItem> items;

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;
    final tokens = context.tokens;
    final textTheme = Theme.of(context).textTheme;

    if (items.isEmpty) {
      return ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: EdgeInsets.all(tokens.pagePadding),
        children: const [
          EmptyState(icon: Icons.inbox_rounded, title: '暂无数据'),
        ],
      );
    }

    final groups = groupByDay(items);
    return ListView(
      physics: const AlwaysScrollableScrollPhysics(),
      padding: EdgeInsets.fromLTRB(
        tokens.pagePadding,
        tokens.spaceSm,
        tokens.pagePadding,
        tokens.spaceXl,
      ),
      children: [
        AppCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                '合计',
                style: textTheme.labelLarge?.copyWith(
                  color: palette.onSurfaceVariant,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                formatYuanDetail(totalCentsOf(items)),
                style: textTheme.displaySmall,
              ),
              const SizedBox(height: 4),
              Text(
                '共 ${formatCount(items.length)} 条 · 下拉可刷新',
                style: textTheme.bodySmall?.copyWith(
                  color: palette.onSurfaceVariant,
                ),
              ),
            ],
          ),
        ),
        for (final group in groups) ...[
          Padding(
            padding: EdgeInsets.only(
              top: tokens.spaceLg,
              bottom: tokens.spaceSm,
            ),
            child: Text(
              formatDayTitle(group.day),
              style: textTheme.labelLarge?.copyWith(
                color: palette.onSurfaceVariant,
              ),
            ),
          ),
          AppCard(
            padding: EdgeInsets.symmetric(
              horizontal: tokens.spaceMd,
              vertical: tokens.spaceXs,
            ),
            child: Column(
              children: [
                for (var i = 0; i < group.items.length; i++) ...[
                  if (i > 0)
                    Divider(height: 1, color: palette.outlineVariant),
                  SampleRow(item: group.items[i]),
                ],
              ],
            ),
          ),
        ],
      ],
    );
  }
}
