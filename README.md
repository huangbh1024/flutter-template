# Flutter 应用开发模版

基于 [车小记](https://github.com/huangbh1024/chexiaoji-app) 的工程实践整理：
feature-first 分层、Riverpod 状态管理、Material 3 主题 token、
Android / iOS 双端 CI 打包，以及面向 AI 代理的协作规范。

## 包含内容

```text
.
├── CLAUDE.md                  # AI / 自动化代理规范（最高约束）
├── AGENTS.md                  # 代理规范速查
├── CONTRIBUTING.md            # 分支、CI、签名、开发流程
├── docs/
│   ├── architecture.md        # 分层、数据流、主题、测试约定
│   ├── CI.md                  # Android / iOS CI 与签名说明
│   └── DEBUG.md               # 真机调试面板（ISpect）使用说明
├── .github/
│   ├── actions/setup-flutter/ # 工作流共用：安装 Flutter + 缓存
│   ├── workflows/
│   │   ├── flutter-android.yml # PR verify + main 构建 APK
│   │   ├── flutter-ios.yml     # main / 手动构建 IPA
│   │   ├── flutter-debug-apk.yml # debug/** 或手动：带调试面板的 profile APK
│   │   └── release.yml         # tag 发布签名包 + GitHub Release
│   └── dependabot.yml         # actions / pub 依赖周更
├── .editorconfig              # 编辑器基础设置
├── .gitattributes             # 统一 LF
├── .metadata                  # Flutter 项目元数据
├── lib/                       # 分层脚手架 + 示例 feature
├── test/                      # 单测与 widget 测试示例
├── android/                   # 已接入 release 签名配置
├── ios/                       # Runner 工程（未签名，CI 支持签名导入）
├── .vscode/launch.json        # 调试配置（debug / profile 默认开调试面板）
└── tool/
    ├── rename_project.sh      # 一键改包名 / 显示名
    └── run_debug.sh           # 开发启动脚本（默认开调试面板）
```

## 快速开始

1. 复制模板到新目录（模板本身未初始化 git）：

   ```bash
   cp -r flutter-template my_app
   cd my_app
   ```

2. 修改项目标识（包名、显示名、pubspec 名称）：

   ```bash
   tool/rename_project.sh com.yourcompany.myapp "我的应用"
   # 可选：指定 Dart 包名
   tool/rename_project.sh com.yourcompany.myapp "我的应用" my_app
   ```

   脚本会同步修改 `pubspec.yaml`、Dart import、Android namespace /
   applicationId / MainActivity 包路径、iOS Bundle ID、两端显示名与测试目标。

3. 安装依赖并运行：

   ```bash
   flutter pub get
   dart format lib test
   flutter analyze
   flutter test
   flutter run
   ```

4. 初始化仓库并建立分支保护：

   ```bash
   git init
   git add .
   git commit -m "chore: 初始化项目"
   git branch -M main
   gh repo create <repo> --private --source=. --remote=origin --push
   ```

   GitHub → Settings → Branches → 保护 `main`：

   - 禁止直接 push，必须 PR；
   - 必须通过 `verify` 检查；
   - 禁止 force push / 删除分支。

5. 配置签名 secrets（可选，详见 [docs/CI.md](docs/CI.md)）：

   - Android：`ANDROID_KEYSTORE_BASE64`、`ANDROID_KEYSTORE_PASSWORD`、
     `ANDROID_KEY_ALIAS`、`ANDROID_KEY_PASSWORD`
   - iOS：`IOS_CERTIFICATE_BASE64`、`IOS_CERTIFICATE_PASSWORD`、
     `IOS_PROVISIONING_PROFILE_BASE64`、`IOS_TEAM_ID`，Variable
     `IOS_EXPORT_METHOD`

## CI 行为

| 事件 | 结果 |
| --- | --- |
| PR → `main` | `verify`：`pub get` + `format` 检查 + `analyze` + `test`，不打包 |
| PR 合并进 `main` | 构建 Android APK（arm64）与 iOS IPA，上传 Artifact |
| 推送 `v*` tag | 构建签名 APK / IPA 并创建 GitHub Release |
| 只改文档的合并 | 不触发构建 |
| 推送 `debug/**` 分支 / Debug APK 工作流 | 构建带调试面板的 profile APK（Artifact） |
| Actions → Run workflow | 手动出 Android / iOS 包 |

## 开发约定（摘要）

- 不直接 push `main`，一律 `feat/*`、`fix/*` … 分支 + PR；
- 页面只通过 provider 取数，仓库接口与 Mock 实现分离；
- 金额用整数分，日期展示统一走 `core/format`；
- 颜色 / 间距从 `context.palette` / `context.tokens` 取；
- 提交前 `dart format` 无 diff、`flutter analyze` 零 issue、`flutter test` 全绿；
- 真机调试面板：用 `./tool/run_debug.sh` 或 VS Code 的 debug 配置启动会默认开启；
  release 构建自动关闭，详见 [docs/DEBUG.md](docs/DEBUG.md)。

完整规则见 [CLAUDE.md](CLAUDE.md)，架构说明见
[docs/architecture.md](docs/architecture.md)。

## 维护模板

- Flutter 版本只写在 `.github/actions/setup-flutter/action.yml` 的默认值里，
  升级时同步 `CLAUDE.md` 与 `docs/CI.md`；Java / SDK 版本见 `docs/CI.md`；
- 升级 Flutter 后重新生成原生工程时，注意保留 `android/app/build.gradle.kts`
  的 release 签名配置与 `ios/Runner/Info.plist` 的显示名；
- 模板中的示例 feature（`lib/features/sample`）在真实项目中替换为业务模块。
