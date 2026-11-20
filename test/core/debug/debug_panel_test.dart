import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_app_template/core/debug/debug_panel.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('shouldEnableDebugPanel', () {
    test('没有编译期开关时保持关闭', () {
      expect(shouldEnableDebugPanel(flag: false, isRelease: false), isFalse);
    });

    test('release 构建即使开了开关也关闭', () {
      expect(shouldEnableDebugPanel(flag: true, isRelease: true), isFalse);
    });

    test('debug / profile 且开关打开时启用', () {
      expect(shouldEnableDebugPanel(flag: true, isRelease: false), isTrue);
    });
  });

  test(
    '默认构建不启用调试面板',
    () {
      expect(debugPanelEnabled, isFalse);
    },
    skip: const bool.fromEnvironment('ISPECT_ENABLED')
        ? '当前构建已通过 dart-define 启用面板'
        : false,
  );

  group(
    '面板关闭时全部是空实现',
    () {
      test('localizations delegate 为空列表', () {
        expect(debugLocalizationsDelegates(), isEmpty);
      });

      test('navigator observer 原样返回传入列表', () {
        expect(debugNavigatorObservers(), isEmpty);
        expect(
          debugNavigatorObservers(additional: [_NoopObserver()]),
          hasLength(1),
        );
      });

      test('不创建导航观察者', () {
        expect(debugNavigatorObserver, isNull);
      });
    },
    skip: debugPanelEnabled
        ? '当前构建已启用面板'
        : (kReleaseMode ? '当前处于 release 构建' : false),
  );
}

class _NoopObserver extends NavigatorObserver {}
