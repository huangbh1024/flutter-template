# CI 构建（GitHub Actions）

本模板包含两个工作流：

| 工作流 | 文件 | 职责 |
| --- | --- | --- |
| Flutter Android | `.github/workflows/flutter-android.yml` | `verify` 检查 + Android APK |
| Flutter iOS | `.github/workflows/flutter-ios.yml` | iOS IPA |

## 触发

| 事件 | Flutter Android | Flutter iOS |
| --- | --- | --- |
| PR → `main` | 只跑 `pub get` / `analyze` / `test`（`verify`） | 不触发 |
| push → `main`（PR 合并后） | `verify` + 构建 release arm64 APK + 上传 Artifact | 构建 IPA + 上传 Artifact |
| push → `main`，只改文档 | 不触发 | 不触发 |
| workflow_dispatch | 手动出 Android 包 | 手动出 iOS 包 |

`push` 事件忽略以下路径（两个工作流相同）：

```yaml
paths-ignore:
  - '**.md'
  - 'docs/**'
  - 'LICENSE'
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

## Android 流程

1. Java 21 + Flutter 3.50.0 stable（带缓存）
2. 安装 Android SDK `platforms;android-36`、`build-tools;36.0.0`
3. `flutter pub get` → `flutter analyze` → `flutter test`
4. 仅 main / 手动触发：
   - 若配置了 Android 签名 secrets，生成 `android/key.properties` 与
     `android/app/upload-keystore.jks`；
   - `flutter build apk --release --target-platform android-arm64`
5. 仅 main / 手动触发：上传 APK Artifact，保留 7 天

需要同时产出多 ABI 或 App Bundle 时，修改构建命令，例如：

```bash
flutter build apk --release --split-per-abi
flutter build appbundle --release
```

产物路径相应改为 `build/app/outputs/flutter-apk/*.apk` 或
`build/app/outputs/bundle/release/*.aab`，并同步修改上传步骤。

## iOS 流程

1. `macos-latest` + Flutter 3.50.0 stable
2. `flutter pub get`
3. 若配置了 iOS 签名 secrets：
   - 导入证书到临时 keychain；
   - 安装描述文件；
   - 根据 `IOS_EXPORT_METHOD` 生成 `ios/ExportOptions.plist`；
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
> `PRODUCT_BUNDLE_IDENTIFIER`。手动签名场景可能需要在 `ExportOptions.plist`
> 中补充 `provisioningProfiles` 映射，按 Xcode 导出的模板填写。

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
仅适合内测。

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

## 费用

- 公开仓库：标准 `ubuntu-24.04` runner 免费，Android 打包无额外费用。
- 私有仓库：Linux 2-core 约 $0.006/分钟；**macOS runner 约
  $0.062/分钟（约 10 倍）**，iOS 构建只在 main / 手动触发，避免 PR 阶段浪费。
- Artifact 与缓存有配额，必要时缩短 `retention-days`。
- 建议在 Settings → Billing 设置 spending limit，避免意外账单。

## 下载

Actions → 某次运行 → 页面底部 **Artifacts**：

- `flutter_app_template-android-<run>-<sha>`（APK）
- `flutter_app_template-ios-<run>-<sha>`（IPA）

Artifact 名称取自仓库名，不用手改。
