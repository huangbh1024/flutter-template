# Flutter 客户端工程规范

本文件是所有 AI / 自动化代理在本仓库工作时的**最高约束**，优先级高于代理的默认习惯。
人类开发者请同时阅读 [CONTRIBUTING.md](CONTRIBUTING.md)。

## 技术栈与工具链

- Flutter 3.50.0 stable / Dart `^3.14.0`
- Material 3（`material_ui`）、Riverpod 3（`flutter_riverpod`）、`intl`
- Android：Java 21、compileSdk 36、build-tools 36.0.0、Gradle 9.5
- CI runner：`ubuntu-24.04`（Android）、`macos-latest`（iOS）

不要擅自升级 Flutter / Java / SDK / Gradle 版本；确需升级时单独开 PR，
同步更新 `.github/workflows/*.yml`、本文件和 [docs/CI.md](docs/CI.md)。

## 分支与合并（必须遵守）

- **禁止直接向 `main` 提交或 push**。所有改动——新功能、修复、重构、文档、CI——
  都必须从 `main` 新开分支，走 PR 合并。
- 分支命名：
  - `feat/<topic>` 新功能
  - `fix/<topic>` 修复
  - `refactor/<topic>` 重构
  - `docs/<topic>` 文档
  - `ci/<topic>` CI / 构建
  - `chore/<topic>` 其他工程改动
- 标准流程：
  1. `git switch main && git pull`
  2. `git switch -c <type>/<topic>`
  3. 开发、提交、`git push -u origin <branch>`
  4. `gh pr create --base main --head <branch>`
  5. 等 PR 的 `verify` 检查通过
  6. 合并 PR，删除分支
- 即使用户要求“直接提交到 main”，也应先创建分支并走 PR；只有用户明确要求
  临时绕过规范时才可例外，并在回复中说明。
- 不要修改 `main` 的分支保护规则，不要 force push `main`。
- 提交信息使用 Conventional Commits：`feat:` / `fix:` / `refactor:` / `docs:` /
  `ci:` / `chore:`。

## CI 与打包规范

工作流：

- `.github/workflows/flutter-android.yml`：`verify` + Android APK
- `.github/workflows/flutter-ios.yml`：iOS IPA

规则：

- **PR → `main`**：只运行 `flutter pub get`、`flutter analyze`、`flutter test`
  （`verify` job），**不打包**，iOS 也不构建。
- **PR 合并进 `main` 后**：运行检查并构建 `flutter build apk --release
  --target-platform android-arm64`，上传 APK Artifact（保留 7 天）；
  同时触发 iOS 工作流构建 IPA。
- **只改文档的合并**：`push main` 忽略 `**.md`、`docs/**`、`LICENSE`、
  `.gitignore` 等路径，纯文档改动不触发任何构建；`pull_request` 不过滤，
  保证 `verify` 始终上报（分支保护必需检查）。
- **workflow_dispatch**：手动触发与合并 main 相同，会打 Android + iOS 包。
- 功能分支直接 push 不触发 CI；必须开 PR。
- 不要随意修改触发条件；如需调整，同步更新 `CONTRIBUTING.md` 与 `docs/CI.md`。

## 密钥与签名

- 禁止提交 `android/key.properties`、`*.jks`、`*.keystore`、`*.p12`、
  `*.mobileprovision`、`ios/ExportOptions.plist` 以及任何证书 / 密码。
- Android 正式签名使用 GitHub Actions Secrets：
  `ANDROID_KEYSTORE_BASE64`、`ANDROID_KEYSTORE_PASSWORD`、
  `ANDROID_KEY_ALIAS`、`ANDROID_KEY_PASSWORD`。
- iOS 签名使用 Secrets：`IOS_CERTIFICATE_BASE64`、
  `IOS_CERTIFICATE_PASSWORD`、`IOS_PROVISIONING_PROFILE_BASE64`、
  `IOS_TEAM_ID`；导出方式用 Repository Variable `IOS_EXPORT_METHOD`。
- 未配置 Android secrets 时 release 包使用 debug 签名，仅适合内测；
  未配置 iOS secrets 时 CI 只产出未签名 IPA，不能安装或上架。
- **全量 APK 更新必须使用固定 release 签名**，否则新旧包签名不同，
  系统会拒绝覆盖安装。

## 架构规范

目录采用 feature-first：

```text
lib/
  app/                  应用入口、主壳、主题
  core/                 跨 feature 的领域基元、格式化、通用组件
  features/<feature>/
    data/               仓库接口与实现（Mock / HTTP）
    domain/             模型、provider、纯逻辑 presenter
    presentation/       页面与私有 widget
```

- `data/` 定义抽象 Repository 并提供实现；页面不直接 new 实现。
- `domain/` 不 import `presentation/`；纯函数（统计、分组、校验）放这里，
  以便脱离 Widget 写单测。
- `presentation/` 只通过 provider 取数据，不直接依赖网络 / 存储实现；
  页面私有 widget 放 `presentation/widgets/`，跨 feature 复用才提升到
  `lib/core/widgets/`。
- 状态管理统一使用 Riverpod。provider 放在对应 feature 的
  `domain/providers.dart`；全局 provider 放 `core/` 或 `app/`。
- 颜色、间距、圆角、阴影统一从 `context.palette` / `context.tokens` /
  `Theme.of(context).textTheme` 取，禁止在页面里硬编码色值与魔法数字。
- 金额在数据层一律用整数「分」；日期用 `DateTime`，展示统一经
  `lib/core/format/formatters.dart`。
- 注释用中文，解释“为什么”而不是复述代码。

## 编码规范

- 提交前必须 `flutter analyze` 零 issue、`flutter test` 全绿。
- 新增 `domain` / `presenter` 逻辑必须带单测；修 bug 先补回归测试。
- 优先 `const`；禁止 `print`（调试用 `debugPrint`）；异常要有用户可读文案。
- 文件名 `snake_case.dart`，类名 `PascalCase`，常量 `lowerCamelCase`。
- 不要为了绕过检查大面积 `// ignore`；不要提交 `build/`、`.dart_tool/`、
  `android/local.properties`、`ios/Flutter/Generated.xcconfig` 等生成物。

## 常用命令

```bash
flutter pub get
flutter analyze
flutter test

# 本地构建（优先走 CI；本地仅用于调试）
flutter build apk --release --target-platform android-arm64
flutter build ios --release --no-codesign   # 需要 macOS + Xcode
```

## Agent 工作流

1. 先读本文件、[CONTRIBUTING.md](CONTRIBUTING.md)、[docs/CI.md](docs/CI.md)。
2. `git switch main && git pull`，再 `git switch -c <type>/<topic>`。
3. 实现改动，同时补测试。
4. 运行 `flutter analyze` 与 `flutter test`，全部通过后再提交。
5. `git push -u origin <branch>`，`gh pr create --base main`。
6. 等待 `verify` 通过；失败先修，不要用 `--no-verify` 或跳过检查。
7. 合并 PR（用户确认后），删除分支。

## 禁止事项

- 直接 push / force push `main`，修改分支保护规则。
- 提交密钥、证书、签名配置或任何本地生成文件。
- 跳过 `flutter analyze` / `flutter test` 直接提交。
- 未经确认修改 CI 触发条件、工具链版本或打包平台范围。
- 在 `presentation/` 里写业务计算逻辑，或让 `domain/` 依赖 Flutter 页面。
