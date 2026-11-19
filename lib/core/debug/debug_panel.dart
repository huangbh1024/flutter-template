import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:ispect/ispect.dart';

/// 编译期开关：只有显式传 `--dart-define=ISPECT_ENABLED=true` 才为 true。
const bool _ispectEnabled = bool.fromEnvironment('ISPECT_ENABLED');

/// 调试面板是否启用：需要编译期开关打开，且不是 release 构建。
///
/// 拆成纯函数便于单测覆盖 debug / release 两种组合，
/// 不必真的打 release 包验证。
bool shouldEnableDebugPanel({required bool flag, required bool isRelease}) =>
    flag && !isRelease;

/// 当前构建是否启用屏内调试面板。
bool get debugPanelEnabled =>
    shouldEnableDebugPanel(flag: _ispectEnabled, isRelease: kReleaseMode);

ISpectNavigatorObserver? _navigatorObserver;

/// 面板用的导航观察者；未启用时不创建，避免多余对象。
ISpectNavigatorObserver? get debugNavigatorObserver {
  if (!debugPanelEnabled) return null;
  return _navigatorObserver ??= ISpectNavigatorObserver();
}

/// 启动应用；启用面板时交给 ISpect 初始化日志与异常收集。
void runWithDebugPanel(VoidCallback app) {
  if (!debugPanelEnabled) {
    app();
    return;
  }
  ISpect.run(app);
}

/// 追加面板自身的中文文案 delegate；未启用时返回空列表。
List<LocalizationsDelegate<dynamic>> debugLocalizationsDelegates() {
  if (!debugPanelEnabled) return const [];
  return ISpectLocalizations.delegate();
}

/// 追加导航观察者；未启用时原样返回 [additional]。
List<NavigatorObserver> debugNavigatorObservers({
  List<NavigatorObserver> additional = const [],
}) {
  if (!debugPanelEnabled) return additional;
  return ISpectNavigatorObserver.observers(
    observer: debugNavigatorObserver,
    additional: additional,
  );
}

/// 包在 `MaterialApp.builder` 中挂载悬浮调试面板；未启用时原样返回 [child]。
Widget wrapWithDebugPanel({required Widget child}) {
  if (!debugPanelEnabled) return child;
  return ISpectBuilder.wrap(
    child: child,
    options: ISpectOptions(
      // 面板自身的中文文案；ISpect 的生成式本地化包含 zh。
      locale: const Locale('zh'),
      observer: debugNavigatorObserver,
    ),
  );
}
