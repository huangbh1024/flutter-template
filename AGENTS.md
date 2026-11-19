# Agent 规范

本仓库面向所有 AI / 自动化代理的完整规范见 [CLAUDE.md](CLAUDE.md)，必须遵守。

核心规则：

1. **不要直接提交或 push `main`**。所有改动从 `main` 新开分支，走 PR。
2. 分支命名：`feat/*`、`fix/*`、`refactor/*`、`docs/*`、`ci/*`、`chore/*`。
3. PR 阶段 CI 只跑 `dart format` 检查 / `flutter analyze` / `flutter test`（`verify`），**不打包**。
4. 只有 PR 合并进 `main`（或手动 `workflow_dispatch`）才构建 Android APK 与 iOS IPA。
5. 不提交 `key.properties`、`*.jks`、`*.keystore`、证书或 `ios/ExportOptions.plist`。
6. 提交信息使用 Conventional Commits。
7. 不要修改 `main` 的分支保护规则或强制推送 `main`。
8. 提交前必须 `dart format` 无 diff、`flutter analyze` 零 issue、`flutter test` 全绿。

流程细节见 [CONTRIBUTING.md](CONTRIBUTING.md)，CI 说明见 [docs/CI.md](docs/CI.md)。
