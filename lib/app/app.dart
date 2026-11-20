import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:material_ui/material_ui.dart';

import '../core/config/app_config.dart';
import '../core/debug/debug_panel.dart';
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
      // 固定中文：Material 内置组件（日期选择器、文本菜单等）不会回退成英文。
      // material_ui 的 delegates 已包含 Material / Widgets / Cupertino 三个 delegate；
      // 需要多语言时改为 ARB + gen_l10n，并删掉固定的 [locale]。
      locale: const Locale('zh', 'CN'),
      supportedLocales: const [Locale('zh', 'CN'), Locale('en')],
      localizationsDelegates: [
        ...GlobalMaterialLocalizations.delegates,
        // 仅调试面板启用时追加，release 下为空列表。
        ...debugLocalizationsDelegates(),
      ],
      navigatorObservers: debugNavigatorObservers(),
      builder: (context, child) =>
          wrapWithDebugPanel(child: child ?? const SizedBox.shrink()),
      home: const AppShell(),
    );
  }
}
