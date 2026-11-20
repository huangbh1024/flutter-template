#!/usr/bin/env bash
# 以 debug 模式启动，并默认带屏内调试面板。
#
# ISpect 的开关是编译期常量（ISPECT_ENABLED），不传 dart-define 时面板不会挂载，
# 因此这里统一带上，避免每次手写。额外参数原样透传给 flutter run：
#   ./tool/run_debug.sh -d <deviceId>
set -euo pipefail
cd "$(dirname "$0")/.."
exec flutter run --dart-define=ISPECT_ENABLED=true "$@"
