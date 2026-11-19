# 真机调试面板（ISpect）

模板内置 [ISpect](https://pub.dev/packages/ispect) 屏内调试面板，用来替代 web 端的
vConsole：不连电脑也能在真机 / QA 包上查看日志、异常、Widget 树与导航记录。

## 启用与关闭

```bash
# 需要面板时（debug / profile 均可）
flutter run --dart-define=ISPECT_ENABLED=true

# 普通开发、CI、release：不传参数，面板完全不参与构建
flutter run
flutter build apk --release
```

- 默认关闭：开关是 `bool.fromEnvironment('ISPECT_ENABLED')`，且额外要求
  `!kReleaseMode`。不满足时 `runWithDebugPanel` 只执行原 `runApp`，
  delegate / observer 全部返回空实现，release 构建可 tree-shake。
- **release 包即使传了 `--dart-define=ISPECT_ENABLED=true` 也不会启用。**

## 接入点

| 文件 | 作用 |
| --- | --- |
| `lib/core/debug/debug_panel.dart` | 开关判断、ISpect 初始化、本地化 delegate、导航观察者、`MaterialApp.builder` 包装 |
| `lib/main.dart` | 用 `runWithDebugPanel(...)` 包住 `runApp` |
| `lib/app/app.dart` | `localizationsDelegates` / `navigatorObservers` / `builder` 三个挂载点 |

## 能看什么

- 日志：`debugPrint`、`dart:developer` 的 `log()`、Flutter / 异步未捕获异常；
- Widget 树与布局检查、颜色拾取、掉帧性能浮层、导航记录、日志导出（可丢进
  ISpect 的 web viewer 回放）。

网络 / 数据库 / Riverpod 生命周期需要额外 adapter，按需添加（版本与 `ispect` 对齐）：

```yaml
# 接入 Dio 后
ispectify_dio: 8.0.0-dev.1
# 需要看 provider 生命周期时
ispectify_riverpod: 8.0.0-dev.1
```

本模板暂时没有 HTTP 层，因此未接入网络 adapter。

## 平台与版本

- Android / iOS 均可：面板是纯 Flutter 实现，无原生 UI；唯一原生依赖是
  `path_provider`（导出日志文件），两端都支持，无需额外权限。
- 锁在 `ispect: 8.0.0-dev.1`：这是首个基于 `material_ui` 的版本，能直接读取模板的
  Material 3 主题。7.x 仍基于 SDK 的 `package:flutter/material.dart`，与本工程的
  `material_ui` 是两套类型，面板会因找不到 `MaterialLocalizations` 报错。
- 该版本要求 `material_ui >= 1.11.0`，`pubspec.lock` 已解析到 1.11.1。
- 预发布版本，升级前先跑：
  `flutter test --dart-define=ISPECT_ENABLED=true`（会执行面板挂载冒烟测试，
  普通 `flutter test` 下该用例自动跳过）。
- 面板会记录日志与请求内容：分享导出前确认脱敏设置，不要把带敏感数据的日志外发。

## 移除

删除 `lib/core/debug/debug_panel.dart`，还原 `lib/main.dart` 与 `lib/app/app.dart`
的三处接入，并从 `pubspec.yaml` 去掉 `ispect` 依赖。
