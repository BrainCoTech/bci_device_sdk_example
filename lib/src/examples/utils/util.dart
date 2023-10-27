// ignore_for_file: prefer_function_declarations_over_variables

import 'dart:async';

import 'package:flutter/gestures.dart';

export 'permission_util.dart';
export 'shared_preference.dart';
export 'validate_util.dart';

/// 函数防抖
///
/// [func]: 要执行的方法
/// [delay]: 要迟延的时长
GestureTapCallback tapDebounce(
  Function func, {
  Duration delay = const Duration(milliseconds: 500),
}) {
  Timer? timer;
  final target = () {
    if (timer?.isActive ?? false) {
      timer?.cancel();
    }
    timer = Timer(delay, () {
      func.call();
    });
  };
  return target;
}

/// 函数节流
///
/// [func]: 要执行的方法
Function throttle(
  Future Function() func,
) {
  var enable = true;
  Function target = () {
    if (enable == true) {
      enable = false;
      func().then((_) {
        enable = true;
      });
    }
  };
  return target;
}
