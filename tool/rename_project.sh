#!/usr/bin/env bash
# 把模板改成新的项目标识：包名、Dart 包名、两端显示名。
#
# 用法：
#   tool/rename_project.sh <bundle_id> <display_name> [package_name]
#   tool/rename_project.sh --dry-run <bundle_id> <display_name> [package_name]
#
# 示例：
#   tool/rename_project.sh com.acme.notes "随手记"
#   tool/rename_project.sh com.acme.notes "随手记" notes_app
#
# 说明：
# - bundle_id 同时用于 Android applicationId / namespace 与 iOS Bundle ID，
#   只允许字母、数字和点（不能有下划线或连字符），以保证两端都合法；
# - display_name 是桌面图标下的名称，可含中文；
# - package_name 是 Dart 包名（默认取 bundle_id 最后一段），snake_case；
# - 加 --dry-run 只打印将要修改的文件，不落盘。
#
# 脚本可重复执行：模板标识已被替换时会提示并退出。

set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$ROOT"

OLD_BUNDLE_ANDROID="com.example.flutter_app_template"
OLD_BUNDLE_IOS="com.example.flutterAppTemplate"
OLD_PACKAGE="flutter_app_template"
OLD_DISPLAY_NAME="Flutter Template"
OLD_APP_NAME="App 模板"

usage() {
  sed -n '2,/^$/p' "${BASH_SOURCE[0]}" | sed 's/^# \{0,1\}//'
  exit "${1:-1}"
}

# --dry-run 只预览，不修改磁盘；--help 打印用法。
DRY_RUN=0
POSITIONAL=()
for arg in "$@"; do
  case "$arg" in
    --dry-run) DRY_RUN=1 ;;
    -h|--help) usage 0 ;;
    *) POSITIONAL+=("$arg") ;;
  esac
done
if [ ${#POSITIONAL[@]} -gt 0 ]; then
  set -- "${POSITIONAL[@]}"
else
  set --
fi

if [ $# -lt 2 ] || [ $# -gt 3 ]; then
  usage 1
fi

BUNDLE_ID="$1"
DISPLAY_NAME="$2"

bundle_to_package() {
  local last="${1##*.}"
  printf '%s' "$last" \
    | tr '[:upper:]' '[:lower:]' \
    | sed 's/[^a-z0-9_]/_/g'
}

PACKAGE_NAME="${3:-$(bundle_to_package "$BUNDLE_ID")}"

if ! printf '%s' "$BUNDLE_ID" | grep -Eq '^[A-Za-z][A-Za-z0-9]*(\.[A-Za-z][A-Za-z0-9]*)+$'; then
  echo "错误：bundle_id 需为反向域名，只含字母、数字和点，例如 com.acme.app" >&2
  exit 1
fi

if ! printf '%s' "$PACKAGE_NAME" | grep -Eq '^[a-z][a-z0-9_]*$'; then
  echo "错误：Dart 包名需为 snake_case，只含小写字母、数字、下划线，例如 my_app" >&2
  exit 1
fi

if [ -z "$DISPLAY_NAME" ]; then
  echo "错误：显示名不能为空" >&2
  exit 1
fi

if [ -f pubspec.yaml ] && ! grep -q "^name: ${OLD_PACKAGE}$" pubspec.yaml; then
  echo "提示：pubspec.yaml 中已不是模板包名，可能已经改过名。未做任何修改。" >&2
  exit 1
fi

# sed 替换字符串转义（分隔符使用 |）。
escape_replacement() {
  printf '%s' "$1" | sed -e 's/[\\|&]/\\&/g'
}

# sed 正则模式转义。
escape_pattern() {
  printf '%s' "$1" | sed -e 's/[][\\.^$*+?(){}|/]/\\&/g'
}

replace_in_file() {
  local old="$1" new="$2" file="$3"
  [ -f "$file" ] || return 0
  grep -qF -- "$old" "$file" || return 0
  if [ "$DRY_RUN" -eq 1 ]; then
    echo "  [dry-run] ${file#"$ROOT"/}: ${old} -> ${new}"
    return 0
  fi
  local pattern
  pattern="$(escape_pattern "$old")"
  sed -i.bak "s|${pattern}|${new}|g" "$file"
  rm -f "${file}.bak"
}

# 收集需要处理的文本文件，跳过生成物与工具目录。
collect_files() {
  find "$ROOT/lib" "$ROOT/test" "$ROOT/android" "$ROOT/ios" "$ROOT/docs" \
    -type f \
    \( -name '*.dart' -o -name '*.yaml' -o -name '*.kts' -o -name '*.kt' \
       -o -name '*.xml' -o -name '*.plist' -o -name '*.pbxproj' \
       -o -name '*.swift' -o -name '*.md' \) \
    -not -path '*/build/*' -not -path '*/.gradle/*' -not -path '*/ephemeral/*'
}

NEW_BUNDLE_ESCAPED="$(escape_replacement "$BUNDLE_ID")"
NEW_PACKAGE_ESCAPED="$(escape_replacement "$PACKAGE_NAME")"
NEW_DISPLAY_ESCAPED="$(escape_replacement "$DISPLAY_NAME")"

while IFS= read -r file; do
  replace_in_file "$OLD_BUNDLE_ANDROID" "$NEW_BUNDLE_ESCAPED" "$file"
  replace_in_file "$OLD_BUNDLE_IOS" "$NEW_BUNDLE_ESCAPED" "$file"
  replace_in_file "$OLD_PACKAGE" "$NEW_PACKAGE_ESCAPED" "$file"
  replace_in_file "$OLD_DISPLAY_NAME" "$NEW_DISPLAY_ESCAPED" "$file"
done < <(collect_files)

# 应用内显示名在 app_config.dart 里。
replace_in_file "$OLD_APP_NAME" "$NEW_DISPLAY_ESCAPED" \
  "$ROOT/lib/core/config/app_config.dart"

# pubspec 的 name 行（前面只替换了字符串，行首 name 不变，这里确认并替换）。
if [ "$DRY_RUN" -eq 1 ]; then
  echo "  [dry-run] pubspec.yaml: name: ${OLD_PACKAGE} -> name: ${PACKAGE_NAME}"
else
  sed -i.bak "s|^name: ${OLD_PACKAGE}$|name: ${PACKAGE_NAME}|" "$ROOT/pubspec.yaml"
  rm -f "$ROOT/pubspec.yaml.bak"
fi

# Android：MainActivity 的包路径跟随 namespace 移动。
OLD_KOTLIN_DIR="$ROOT/android/app/src/main/kotlin/${OLD_BUNDLE_ANDROID//.//}"
NEW_KOTLIN_DIR="$ROOT/android/app/src/main/kotlin/${BUNDLE_ID//.//}"
if [ -d "$OLD_KOTLIN_DIR" ] && [ "$DRY_RUN" -eq 1 ]; then
  echo "  [dry-run] ${OLD_KOTLIN_DIR#"$ROOT"/} -> ${NEW_KOTLIN_DIR#"$ROOT"/}"
elif [ -d "$OLD_KOTLIN_DIR" ]; then
  mkdir -p "$NEW_KOTLIN_DIR"
  mv "$OLD_KOTLIN_DIR/MainActivity.kt" "$NEW_KOTLIN_DIR/MainActivity.kt"
  # 自底向上清理空的旧包目录（macOS find 不支持 -delete）。
  dir="$OLD_KOTLIN_DIR"
  while [ "$dir" != "$ROOT/android/app/src/main/kotlin" ] && rmdir "$dir" 2>/dev/null; do
    dir="$(dirname "$dir")"
  done
fi

# iOS：Info.plist 的 CFBundleName 使用新包名（上面已按 OLD_PACKAGE 替换）。
# plist 中 CFBundleDisplayName 已由显示名替换完成。

if [ "$DRY_RUN" -eq 1 ]; then
  echo
  echo "以上为预览，未修改任何文件。去掉 --dry-run 重新执行即可生效。"
  exit 0
fi

echo "已更新项目标识："
echo "  Bundle ID   : $BUNDLE_ID"
echo "  Dart 包名   : $PACKAGE_NAME"
echo "  显示名      : $DISPLAY_NAME"
echo
echo "后续步骤："
echo "  1. flutter pub get && flutter analyze && flutter test"
echo "  2. 按需修改 lib/core/config/app_config.dart、图标与启动图"
echo "  3. git init 后配置 main 分支保护，要求 verify 检查"
echo "  4. 在 GitHub Actions 配置签名 secrets（见 docs/CI.md）"
