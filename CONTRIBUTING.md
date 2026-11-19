# 开发与分支规范

## 环境准备

- Flutter 3.50.0 stable（`flutter --version` 核对）
- JDK 21（Android 构建；`compileOptions` / `jvmTarget` 仍为 17，与 Flutter 默认一致）
- Android SDK 36 / build-tools 36.0.0
- macOS + Xcode（仅 iOS 构建需要）

```bash
flutter pub get
dart format lib test
flutter analyze
flutter test
flutter run
```

## 分支命名

所有新功能、修复、文档和 CI 改动都从 `main` 新开分支，不直接提交到 `main`。

| 类型 | 命名示例 |
| --- | --- |
| 新功能 | `feat/order-list`、`feat/sms-login` |
| 修复 | `fix/login-timeout` |
| 重构 | `refactor/api-client` |
| 文档 | `docs/ci-flow` |
| 工程/CI | `ci/package-on-main`、`chore/upgrade-flutter` |

## 开发流程

```bash
git switch main
git pull
git switch -c feat/your-feature

# 开发、提交
dart format lib test
flutter analyze
flutter test
git add .
git commit -m "feat: 实现 xxx"
git push -u origin feat/your-feature

# 开 PR（目标 main）
gh pr create --base main --head feat/your-feature --fill
```

## CI 规则

- **PR 阶段**：只运行 `flutter pub get`、`dart format` 检查、`flutter analyze`、
  `flutter test`，**不打包**。
- **合并进 `main` 后**：自动运行完整检查，构建 Android release arm64 APK 与
  iOS IPA，上传到 Actions Artifact。
- **只改文档时**：合并进 `main` 若只涉及 `**.md`、`docs/**`、`.gitignore`、
  `.gitattributes`、`.editorconfig` 等非代码文件，**不会触发**工作流；需要出包时
  在 Actions 页面手动 `Run workflow`。
- **手动触发**：两个工作流都支持 `Run workflow`。
- **tag 发布**：推送 `v<版本>` tag 触发 `release.yml`，tag 去掉 `v` 后必须与
  `pubspec.yaml` 的 `version`（不含 `+build`）一致；发布要求配置两端签名
  secrets，缺少签名会直接失败。

也就是说：**只有 PR 合并进主分支后才产出安装包；正式发布走 tag**。

## 合并要求

`main` 分支启用保护规则：

- 必须通过 PR 合并，禁止直接 push；
- 必须通过 `verify` 状态检查；
- 分支需与 `main` 同步后才能合并；
- 禁止 force push 和删除分支。

PR 检查通过后，使用 GitHub 的 **Merge pull request** 或 **Squash and merge** 合并。

## 提交信息

使用 Conventional Commits：

```text
feat: 新功能
fix: 修复
refactor: 重构
docs: 文档
ci: CI/构建
chore: 其他工程改动
```

## 签名与密钥

- `android/key.properties`、`*.jks`、`*.keystore`、`*.p12`、`*.mobileprovision`
  不要提交；
- Android 正式签名使用 GitHub Actions Secrets：
  `ANDROID_KEYSTORE_BASE64`、`ANDROID_KEYSTORE_PASSWORD`、
  `ANDROID_KEY_ALIAS`、`ANDROID_KEY_PASSWORD`；
- iOS 签名使用 Secrets：`IOS_CERTIFICATE_BASE64`、
  `IOS_CERTIFICATE_PASSWORD`、`IOS_PROVISIONING_PROFILE_BASE64`、
  `IOS_TEAM_ID`，导出方式用 Variable `IOS_EXPORT_METHOD`；
- 未配置 Android secrets 时 release 包使用 debug 签名，仅适合内测；
- 未配置 iOS secrets 时 CI 只产出未签名 IPA，不能安装或上架。

详见 [docs/CI.md](docs/CI.md)。

## 下载安装包

合并进 `main` 后：

1. 打开 GitHub → **Actions** → 最近一次 `Flutter Android` / `Flutter iOS`；
2. 页面底部 **Artifacts** 下载；
3. 或使用 CLI：

```bash
gh run list
gh run download <run-id> --dir ~/Downloads
```

## iOS 本地构建

```bash
flutter build ios --release --no-codesign   # 验证编译，无需证书
open ios/Runner.xcworkspace                 # 真机调试 / 签名在 Xcode 配置
```

App Store 上架需要配置签名证书与描述文件，或在本地 Xcode 中使用自动签名。
