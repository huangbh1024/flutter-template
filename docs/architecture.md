# 架构说明

## 分层

```text
lib/
├── main.dart                  # ProviderScope + runApp
├── app/
│   ├── app.dart               # MaterialApp、主题、全局配置
│   ├── app_shell.dart         # 主壳：标题栏 / 多 Tab / 底部导航
│   └── theme/                 # 语义色、布局 token、字体、ThemeData
├── core/
│   ├── config/                # 应用级常量
│   ├── format/                # 金额、日期等纯格式化函数
│   └── widgets/               # 跨 feature 复用的通用组件
└── features/
    └── <feature>/
        ├── data/              # Repository 接口 + 实现（Mock / HTTP）
        ├── domain/            # 模型、provider、纯逻辑 presenter
        └── presentation/      # 页面与私有 widget
```

依赖方向：`presentation → domain → data`。`domain` 不反向依赖 `presentation`，
`data` 不依赖 Flutter UI。

## 数据流

```text
Widget (presentation)
  └── ref.watch(xxxProvider)            // domain/providers.dart
        └── Provider / Notifier          // 状态与依赖注入
              └── Repository (data)      // 抽象接口
                    └── Mock / HTTP 实现
```

- **页面不直接 new 仓库实现**。实现只在 `providers.dart` 里选择一次。
- 列表 / 详情类数据用 `FutureProvider` 或 `AsyncNotifier`；
  可变的本地状态（筛选、选中项）用 `NotifierProvider`。
- 需要保持状态的 provider 不要加 `autoDispose`；页面级数据建议加。

### 接入真实接口

1. 在 `data/` 新增 `HttpXxxRepository implements XxxRepository`；
2. 在 `domain/providers.dart` 把 `MockXxxRepository()` 换成
   `HttpXxxRepository(client)`；
3. 页面与 provider 消费者不需要改动；
4. Android 需要在 `android/app/src/main/AndroidManifest.xml` 打开
   `INTERNET` 权限（模板里默认注释掉）；iOS 访问非 HTTPS 接口还要在
   `Info.plist` 配置 ATS 例外，正式环境优先用 HTTPS。

## 示例 feature

`features/sample/` 演示了完整链路：

- `domain/sample_item.dart`：不可变模型，金额用整数分；
- `data/sample_repository.dart` + `mock_sample_repository.dart`：接口与 Mock；
- `domain/sample_presenter.dart`：按天分组、合计等纯函数（可直接单测）；
- `domain/providers.dart`：依赖注入与异步数据；
- `presentation/sample_page.dart`：加载 / 失败 / 空 / 有数据四种状态 + 下拉刷新。

新增 feature 时复制这个结构，删除示例即可。

## 主题与设计 token

- 颜色：`context.palette`（`AppPalette`，ThemeExtension）；
- 间距 / 圆角 / 阴影：`context.tokens`（`AppTokens`）；
- 文字：`Theme.of(context).textTheme`（`AppTypography` 生成）；
- 组件默认样式在 `AppTheme._build()` 统一配置。

不要在页面里写 `Color(0xFF...)`、`SizedBox(height: 17)` 这类魔法值；
确需新增 token 时，同时补 light / dark 两套值。

## 本地化

- 应用固定为中文：`MaterialApp` 使用 material_ui 的
  `GlobalMaterialLocalizations.delegates`、`supportedLocales: [zh_CN, en]`，
  Material 内置组件（日期选择器、文本选择菜单等）不会回退成英文；
- 页面文案目前直接写在组件里。需要多语言时引入 `l10n.yaml` + ARB，
  用生成的 `AppLocalizations` 取文案，并删掉 `App` 里固定的 `locale`。

## 金额与日期

- 金额：数据层一律 `int` 分；输入用 `parseYuanToCents`，展示用
  `formatYuanDetail` / `formatYuanCompact` / `splitYuanParts`。
- 日期：数据层保存 `DateTime`（接口返回 UTC 时保留 UTC），
  展示时统一经 `lib/core/format/formatters.dart`，内部 `toLocal()`。
- 测试中涉及“今天 / 昨天”的逻辑，显式传入 `now`，不要依赖系统时间。

## 测试策略

- `domain` 纯函数：普通 `test`，固定输入输出，不碰 Widget；
- provider / notifier：`ProviderContainer.test(overrides: [...])` 单测，
  参考 `test/features/sample/sample_providers_test.dart`；autoDispose 的
  provider 先 `container.listen` 保持存活；
- 页面：`testWidgets` + `ProviderScope(overrides: [...])`，
  用零延迟 Mock 仓库；
- 修 bug 先写复现测试；新增统计 / 分组 / 校验逻辑必须带测试。

```bash
flutter test
flutter test test/features/sample/sample_presenter_test.dart
```
