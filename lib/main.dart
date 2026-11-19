import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:material_ui/material_ui.dart';

import 'app/app.dart';
import 'core/debug/debug_panel.dart';

void main() {
  // 先初始化绑定，保证启动阶段的异常也能进入下面的统一处理。
  WidgetsFlutterBinding.ensureInitialized();

  FlutterError.onError = (details) {
    FlutterError.presentError(details);
    debugPrint('Flutter 异常：${details.exceptionAsString()}');
  };
  PlatformDispatcher.instance.onError = (error, stackTrace) {
    debugPrint('异步异常：$error\n$stackTrace');
    // 返回 true 表示异常已处理，不再交给平台默认处理。
    return true;
  };

  // 未启用调试面板时与原行为完全一致；启用时由 ISpect 接管日志收集。
  runWithDebugPanel(() => runApp(const ProviderScope(child: App())));
}
