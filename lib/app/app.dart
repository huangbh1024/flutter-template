import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:material_ui/material_ui.dart';

import '../core/config/app_config.dart';
import 'app_shell.dart';
import 'theme/app_theme.dart';
import 'theme/theme_mode_provider.dart';

/// 应用根组件：主题、路由入口与全局 ProviderScope 之上的配置都放这里。
class App extends ConsumerWidget {
  const App({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final themeMode = ref.watch(themeModeProvider);
    return MaterialApp(
      title: AppConfig.appName,
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light(),
      darkTheme: AppTheme.dark(),
      themeMode: themeMode,
      themeAnimationDuration: const Duration(milliseconds: 250),
      home: const AppShell(),
    );
  }
}
