# CI 构建（GitHub Actions）

本模板包含四个工作流和四个共用 action：

| 工作流 / action | 文件 | 职责 |
| --- | --- | --- |
| Flutter Android | `.github/workflows/flutter-android.yml` | `verify` 检查 + Android APK |
| Flutter iOS | `.github/workflows/flutter-ios.yml` | iOS IPA |
| Flutter Debug APK | `.github/workflows/flutter-debug-apk.yml` | 带调试面板的 profile APK（内测用） |
| Release | `.github/workflows/release.yml` | tag 发布：签名 APK / IPA + GitHub Release |
| Setup Flutter | `.github/actions/setup-flutter/action.yml` | 安装固定版本 Flutter，缓存 SDK 与 pub 依赖 |
| Verify | `.github/actions/verify/action.yml` | 共享检查：pub get / analyze / test / format |
| Android Signing | `.github/actions/android-signing/action.yml` | 导入 Android release 签名；正式发布缺少 secrets 时失败 |
| iOS Signing | `.github/actions/ios-signing/action.yml` | 导入证书与描述文件，生成带 `provisioningProfiles` 的 ExportOptions |

## 触发

| 事件 | Flutter Android | Flutter iOS | Flutter Debug APK | Release |
| --- | --- | --- | --- | --- |
| PR → `main` | 只跑 `verify`（format / analyze / test） | 不触发 | 不触发 | 不触发 |
| push → `main`（PR 合并后） | `verify` + 构建 release arm64 APK + 上传 Artifact | 构建 IPA + 上传 Artifact | 不触发 | 不触发 |
| push → `main`，只改文档 | 不触发 | 不触发 | 不触发 | 不触发 |
| push `debug/**` 分支 | 不触发 | 不触发 | `verify` + 构建带面板的 profile APK | 不触发 |
| push `v*` tag | 不触发 | 不触发 | 不触发 | 构建签名 APK / IPA 并创建 GitHub Release |
| workflow_dispatch | 手动出 Android 包 | 手动出 iOS 包 | 手动出带面板的 profile APK | 不适用（tag 触发） |

`push` 事件忽略以下路径（Android / iOS 工作流相同）：

```yaml
paths-ignore:
  - '**.md'
  - 'docs/**'
  - '.gitignore'
  - '.gitattributes'
  - '.editorconfig'
  - '.idea/**'
  - '.vscode/**'
```

一次推送里只要有一个非忽略文件（如 `lib/**`、`pubspec.yaml`、`android/**`），
就会正常构建。需要给纯文档改动出包时，用 Actions 页面的 `Run workflow`
手动触发。

> 为什么 PR 不做同样的过滤：`main` 分支保护把 `verify` 设为必需检查。若文档
> 类 PR 被 `paths-ignore` 跳过，`verify` 不会上报，PR 会一直卡在
> “Expected” 无法合并。iOS 工作流不参与 PR 检查，所以只保留 push 触发。

功能分支直接 push 不会触发 CI；先开 PR 到 `main`，合并后才会出包。

## 共用 Setup Flutter

`.github/actions/setup-flutter/action.yml` 统一安装 Flutter 并开启缓存：

```yaml
- uses: subosito/flutter-action@v2.23.0
  with:
    flutter-version: '3.50.0'
    channel: stable
    cache: true
```

`cache: true` 会同时缓存 Flutter SDK 与 `~/.pub-cache`，工作流里不需要再写
`actions/cache`。**升级 Flutter 版本只改这个 action 的默认值**，再同步
`CLAUDE.md` 与本文档。

> `subosito/flutter-action` 没有 `v2` 浮动 tag，必须写到具体版本
> （如 `v2.23.0`），否则 action 无法解析。

## 共用 Verify

`.github/actions/verify/action.yml` 统一执行 `setup-flutter`、
`pub get --enforce-lockfile`、`analyze`、`test` 与 `dart format` 检查。
需要跑检查的工作流直接 `uses: ./.github/actions/verify`，不要再复制步骤。

## Android 流程

### verify（PR 与 main 都跑）

1. `actions/checkout`
2. 调用 `./.github/actions/verify`，依次执行：
   - `./.github/actions/setup-flutter`
   - `flutter pub get --enforce-lockfile`
   - `flutter analyze`
   - `flutter test`
   - `dart format --output=none --set-exit-if-changed lib test`

`verify` 不使用 Android SDK，也不装 Java，PR 反馈更快。
`--enforce-lockfile` 保证 CI 不会在 `pubspec.lock` 之外悄悄升级依赖；
改了 `pubspec.yaml` 却没提交 lock 时这一步会直接失败。

### build（仅 main / 手动触发）

1. Java 21 + Flutter（复用 Setup Flutter）
2. 安装 Android SDK `platforms;android-36`、`build-tools;36.0.0`
3. `flutter pub get`
4. 调用 `.github/actions/android-signing` 导入签名：生成 `android/key.properties`
   与 `android/app/upload-keystore.jks`。未配置 secrets 时回退 debug 签名
   （`release.yml` 传 `required: true`，缺失直接失败）。secrets 以 job 级 `env`
   传入，因为复合 action 读不到 `secrets` 上下文
5. `flutter build apk --release --target-platform android-arm64`
6. 上传 APK Artifact，保留 7 天；签名方式写入 Step Summary

需要同时产出多 ABI 或 App Bundle 时，修改构建命令，例如：

```bash
flutter build apk --release --split-per-abi
flutter build appbundle --release
```

产物路径相应改为 `build/app/outputs/flutter-apk/*.apk` 或
`build/app/outputs/bundle/release/*.aab`，并同步修改上传步骤。

## Debug APK 流程（`.github/workflows/flutter-debug-apk.yml`）

本地无法连接设备时，用 CI 产出「自带屏内调试面板」的安装包：

- 触发：推送到 `debug/**` 分支，或 Actions 页面手动 `Run workflow`（可指定任意分支）；
- 构建：`flutter build apk --profile --dart-define=ISPECT_ENABLED=true
  --target-platform android-arm64`。ISpect 的开关是编译期常量，缺少 define 时面板
  不会挂载；profile 模式 `kReleaseMode=false`，面板可用；
- verify 阶段复用 `.github/actions/verify`，并带
  `--dart-define=ISPECT_ENABLED=true` 跑测试，面板挂载出错会让构建先失败；
- 产物：`<repo>-debug-apk-<run>-<sha>`，保留 7 天；
- 签名：profile 构建类型继承 debug 签名，与 main 的 release 包签名不同，
  **安装前先卸载设备上的旧包**；
- 不影响正式流程：main / tag 仍只产出 release 包，面板在 release 中始终关闭。

## iOS 流程

1. `macos-latest` + Flutter（复用 Setup Flutter）
2. `flutter pub get`
3. 若配置了 iOS 签名 secrets，调用 `.github/actions/ios-signing`：
   - 导入证书到临时 keychain，安装描述文件；
   - 从描述文件读出 profile 名称，从 `ios/Runner.xcodeproj` 读出 Bundle ID，
     按 `IOS_EXPORT_METHOD` 生成带 `provisioningProfiles` 映射的
     `ios/ExportOptions.plist`；
   - `flutter build ipa --release --export-options-plist=ios/ExportOptions.plist`
4. 若未配置签名 secrets：
   - `flutter build ios --release --no-codesign`；
   - 把 `Runner.app` 打包成未签名 `app-unsigned.ipa`，仅用于验证构建。
5. 上传 IPA Artifact，保留 7 天

未签名 IPA **不能安装到真机，也不能上架**。需要可分发产物时配置签名
secrets，或下载构建产物后在本地用 Xcode 重新签名导出。

导出方式（Repository Variable `IOS_EXPORT_METHOD`，默认
`app-store-connect`）：

| 值 | 用途 |
| --- | --- |
| `app-store-connect` | App Store / TestFlight |
| `release-testing` | TestFlight 内测 |
| `ad-hoc` | 指定设备安装 |
| `development` | 开发调试 |

> 如 `flutter build ipa` 报 “No signing certificate / provisioning profile”，
> 检查证书与描述文件是否匹配 `ios/Runner.xcodeproj` 里的
> `PRODUCT_BUNDLE_IDENTIFIER`。`provisioningProfiles` 映射已由
> `.github/actions/ios-signing` 自动写入；描述文件名称与 Bundle ID 不匹配时
> 会先在导入步骤报错。

## Release 流程（tag 发布）

推送 `v*` tag 时触发 `release.yml`：

1. `check-version`：tag 去掉 `v` 后必须与 `pubspec.yaml` 的 `version`
   （不含 `+build`）一致，否则立即失败；
2. `build-android` / `build-ios`：与 main 的构建相同，但**要求配置签名
   secrets**，缺失时直接失败，不会发布未签名产物；
3. `publish`：下载两端产物，`gh release create <tag>` 创建 GitHub Release，
   Release Notes 自动生成。

发布步骤：

```bash
# 1. 在分支上更新 pubspec.yaml 的 version，例如 0.2.0+3
git switch -c chore/release-0.2.0
# 修改 version 后提交并开 PR
git push -u origin chore/release-0.2.0
gh pr create --base main

# 2. PR 合并后，在最新 main 上打 tag
git switch main && git pull
git tag v0.2.0
git push origin v0.2.0
```

tag 与版本号不一致时 `release.yml` 会在 `check-version` 阶段失败，不会产生
Release。

## 签名 secrets 配置

仓库 **Settings → Secrets and variables → Actions**：

### Android

| Secret | 内容 |
| --- | --- |
| `ANDROID_KEYSTORE_BASE64` | `base64 -w0 upload-keystore.jks` |
| `ANDROID_KEYSTORE_PASSWORD` | keystore 密码 |
| `ANDROID_KEY_ALIAS` | 例如 `upload` |
| `ANDROID_KEY_PASSWORD` | key 密码 |

`android/app/build.gradle.kts` 已实现 `signingConfigs.release`，读取
`android/key.properties`。未配置 secrets 时工作流继续使用 debug 签名，
仅适合内测；**正式 Release 必须配置**。

> **全量 APK 更新必须使用固定 release 签名**：不同 CI 运行生成的 debug
> keystore 不同，新旧包签名不一致会导致系统拒绝覆盖安装。

### iOS

| Secret / Variable | 内容 |
| --- | --- |
| `IOS_CERTIFICATE_BASE64` | 导出的 `.p12` 证书，`base64 --decode` 可还原 |
| `IOS_CERTIFICATE_PASSWORD` | `.p12` 密码 |
| `IOS_PROVISIONING_PROFILE_BASE64` | `.mobileprovision` 的 base64 |
| `IOS_TEAM_ID` | Apple Developer Team ID |
| `IOS_EXPORT_METHOD`（Variable） | `app-store-connect` / `ad-hoc` / … |

生成 base64：

```bash
base64 -w0 ~/certs/distribution.p12 > cert.b64
base64 -w0 ~/certs/App_Profile.mobileprovision > profile.b64
```

## 依赖与 action 更新

`.github/dependabot.yml` 每周检查 `github-actions` 与 `pub` 依赖并开 PR：

- actions 的 PR 会带上 `ci:` 前缀，合并前确认 `verify` 通过；
- pub 更新依赖 `pubspec.lock`。模板首次 `flutter pub get` 后请把 lock
  一并提交，否则 dependabot 无法正确解析和更新依赖版本。

## 费用

- 公开仓库：标准 `ubuntu-24.04` runner 免费，Android 打包无额外费用。
- 私有仓库：Linux 2-core 约 $0.006/分钟；**macOS runner 约
  $0.062/分钟（约 10 倍）**，iOS 构建只在 main / tag / 手动触发，避免 PR
  阶段浪费。
- Artifact 与缓存有配额，必要时缩短 `retention-days`。
- 建议在 Settings → Billing 设置 spending limit，避免意外账单。

## 下载

Actions → 某次运行 → 页面底部 **Artifacts**：

- `<repo>-android-<run>-<sha>`（release APK）
- `<repo>-ios-<run>-<sha>`（IPA）
- `<repo>-debug-apk-<run>-<sha>`（带调试面板的 profile APK）

Artifact 名称取自仓库名，不用手改。正式版本请从 GitHub **Releases** 下载。
