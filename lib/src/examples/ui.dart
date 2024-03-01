import 'dart:ui';

import 'package:flutter_easyloading/flutter_easyloading.dart';
import 'package:flutter_utils/flutter_utils.dart';
import 'package:bci_device_sdk_example/logger.dart';
import 'package:bci_device_sdk_example/main.dart';
import 'package:bci_device_sdk_example/src/examples/constants/constant.dart';

/// 默认1倍
extension SizeRatio on num {
  double get scale {
    return ratio * ScreenUtil.designScale;
  }
}

class ScreenUtil {
  static double designScale = 1;
  static double designWidth = 375;
  static double designHeight = 667;

  static void init({
    double? designScale,
    double? designWidth,
    double? designHeight,
  }) async {
    if (designScale != null) ScreenUtil.designScale = designScale;
    if (designWidth != null) ScreenUtil.designWidth = designWidth;
    if (designHeight != null) ScreenUtil.designHeight = designHeight;
    Devices.init(
        width: ScreenUtil.designWidth, height: ScreenUtil.designHeight);
    loggerApp.i(
        'designScale=${ScreenUtil.designScale}, designWidth=${ScreenUtil.designWidth}, designHeight=${ScreenUtil.designHeight}');

    configLoading();
  }

  static Future Function(String? text)? loadingCallback;
  static Future Function({bool animation})? dismissCallback;
  static Future Function(String text)? toastCallback;
  static Future Function(String text)? successCallback;
  static Future Function(String text)? errorCallback;

  static Future<void> showLoading(String? text) {
    if (loadingCallback != null) {
      return loadingCallback!.call(text);
    }
    return EasyLoading.show(status: text);
  }

  static Future<void> dismiss({
    bool animation = true,
  }) {
    if (dismissCallback != null) {
      return dismissCallback!.call(animation: animation);
    }
    return EasyLoading.dismiss(animation: animation);
  }

  static Future<void> showToast(String text) {
    if (toastCallback != null) {
      return toastCallback!.call(text);
    }
    return EasyLoading.showToast(text);
  }

  static Future<void> showSuccess(String text) {
    if (successCallback != null) {
      return successCallback!.call(text);
    }
    return EasyLoading.showSuccess(text);
  }

  static Future<void> showError(String text) {
    if (errorCallback != null) {
      return errorCallback!.call(text);
    }
    return EasyLoading.showError(text);
  }

  static void configLoading() {
    EasyLoading.instance
      ..loadingStyle = EasyLoadingStyle.custom
      ..displayDuration = const Duration(milliseconds: 1000)
      ..radius = 10.scale
      ..indicatorType = EasyLoadingIndicatorType.threeBounce
      ..indicatorSize = 45.scale
      ..indicatorColor = Get.theme.primaryColor
      ..progressColor = Get.theme.primaryColor
      // ..textColor = Get.theme.textTheme.bodyText1?.color
      ..textColor = ColorExt.titleColor
      ..backgroundColor = const Color(0xFF494A5E)
      // ..maskColor = Get.theme.backgroundColor.withOpacity(0.5)
      ..userInteractions = false
      ..dismissOnTap = false;
  }
}
