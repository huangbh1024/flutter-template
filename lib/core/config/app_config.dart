/// 应用级常量。
///
/// [appName] 会被 `tool/rename_project.sh` 一并替换为新的显示名；
/// 页面标题统一引用这里，不要在各处硬编码应用名。
class AppConfig {
  const AppConfig._();

  static const appName = 'App 模板';
}
