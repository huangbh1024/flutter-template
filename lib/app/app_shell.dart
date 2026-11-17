import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:material_ui/material_ui.dart';

import '../core/config/app_config.dart';
import '../features/sample/presentation/sample_page.dart';
import 'theme/app_colors.dart';
import 'theme/theme_mode_provider.dart';

/// 应用主壳：标题栏 + 主题切换 + 当前页面。
///
/// 需要多 Tab 时，在这里加 NavigationBar，并用 IndexedStack 保留页面状态；
/// 路由复杂后可以把 home 换成 go_router 的 Router。
class AppShell extends ConsumerWidget {
  const AppShell({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final palette = context.palette;
    final isDark = ref.watch(themeModeProvider) == ThemeMode.dark;
    return Scaffold(
      backgroundColor: palette.background,
      appBar: AppBar(
        backgroundColor: palette.background,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        title: const Text(AppConfig.appName),
        actions: [
          IconButton(
            tooltip: '切换主题',
            onPressed: () => ref.read(themeModeProvider.notifier).toggle(),
            icon: Icon(
              isDark ? Icons.light_mode_rounded : Icons.dark_mode_rounded,
            ),
          ),
          const SizedBox(width: 4),
        ],
      ),
      body: const SamplePage(),
    );
  }
}
