# 真机调试面板（ISpect）

模板内置 [ISpect](https://pub.dev/packages/ispect) 屏内调试面板，用来替代 web 端的
vConsole：不连电脑也能在真机 / QA 包上查看日志、异常、Widget 树与导航记录。

## 通过 CI 出调试包（推荐）

本地无法连接设备时，用 `Flutter Debug APK` 工作流构建自带面板的安装包：

```bash
# 推一个 debug/** 分支，或对任意分支手动触发
gh workflow run "Flutter Debug APK" --ref feat/your-branch

# 等运行结束后下载 Artifact
gh run list --workflow "Flutter Debug APK"
gh run download <run-id> --dir ~/Downloads
```

- 构建命令：`flutter build apk --profile --dart-define=ISPECT_ENABLED=true
  --target-platform android-arm64`；
- profile 模式 `kReleaseMode=false`，面板可用；Artifact 保留 7 天；
- verify 阶段会跑 `flutter test --dart-define=ISPECT_ENABLED=true`，面板挂载
  出错会直接让构建失败，不会等到装到手机上才发现；
- **安装前先卸载设备上的旧包**：profile 构建继承 debug 签名，与 main 的
  release 包签名不同，无法覆盖安装；
- iOS：未配置签名 secrets 时 CI 只产出未签名 IPA，不能安装。要测 iOS 需先配
  `IOS_CERTIFICATE_BASE64`、`IOS_PROVISIONING_PROFILE_BASE64` 等 secrets
  （见 [docs/CI.md](CI.md)），或在 macOS 本机构建。

## 本地开发（能用 `flutter run` 时）

ISpect 的开关是包内的编译期常量
`const bool kISpectEnabled = bool.fromEnvironment('ISPECT_ENABLED')`，
**没有运行时开关**，默认值为 `false`。所以非 release 包也必须由构建命令带上
`--dart-define`，否则面板不会挂载。仓库已经把这件事固化到开发入口：

```bash
# 推荐：脚本启动，默认带面板（额外参数会透传给 flutter run）
./tool/run_debug.sh
./tool/run_debug.sh -d emulator-5554

# 或者直接用 flutter（必须自己带参数）
flutter run --dart-define=ISPECT_ENABLED=true
```

VS Code 直接按 F5 选 **App (debug, 含调试面板)** 或
**App (profile, 含调试面板)** 即可，配置在 `.vscode/launch.json`。

- 模板自己的门控还额外要求 `!kReleaseMode`：不满足时 `runWithDebugPanel`
  只执行原 `runApp`，delegate / observer 全部返回空实现，release 构建可 tree-shake。
- **release 包即使传了 `--dart-define=ISPECT_ENABLED=true` 也不会启用。**
- Android Studio / IntelliJ 需要手动在 Run Configuration 的
  *Additional run args* 里加 `--dart-define=ISPECT_ENABLED=true`
  （`.idea/` 不入库，无法随模板分发）。

## 接入点

| 文件 | 作用 |
| --- | --- |
| `lib/core/debug/debug_panel.dart` | 开关判断、ISpect 初始化、本地化 delegate、导航观察者、`MaterialApp.builder` 包装 |
| `lib/main.dart` | 用 `runWithDebugPanel(...)` 包住 `runApp` |
| `.github/workflows/flutter-debug-apk.yml` | CI 构建带面板的 profile APK |
| `tool/run_debug.sh` | 本地启动脚本，默认带 `ISPECT_ENABLED=true` |
| `.vscode/launch.json` | VS Code debug / profile 调试配置，默认带面板 |
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
