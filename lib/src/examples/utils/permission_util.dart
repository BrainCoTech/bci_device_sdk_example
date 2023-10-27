// ignore_for_file: unused_element, use_build_context_synchronously

import 'dart:async';
import 'dart:io';

import 'package:app_settings/app_settings.dart';
import 'package:device_info_plus/device_info_plus.dart';
import 'package:flutter/material.dart';
import 'package:bci_device_sdk_example/logger.dart';
import 'package:bci_device_sdk_example/main.dart';
import 'package:permission_handler/permission_handler.dart';

class PermissionUtil {
  static Future<Map<Permission, PermissionStatus>> request(
      Permission permission) async {
    return await [permission].request();
  }

  static bool isGranted(Map<Permission, PermissionStatus> result) {
    return result.values.every((state) => state == PermissionStatus.granted);
  }

  static Future openPermission(BciAppPermission permission) async {
    if (permission == BciAppPermission.location) {
      if (!(await Permission.locationWhenInUse.isGranted)) {
        await AppSettings.openAppSettings();
      } else {
        await AppSettings.openAppSettings(type: AppSettingsType.location);
      }
    } else if (permission == BciAppPermission.bluetooth) {
      if (!(await Permission.bluetooth.isGranted)) {
        await AppSettings.openAppSettings();
      } else {
        if (Platform.isAndroid) {
          await FlutterBlue.instance.requestEnableBluetooth();
        } else {
          await AppSettings.openAppSettings(type: AppSettingsType.settings);
          // 这里打开的是系统蓝牙，Only supported on Android
          // await AppSettings.openAppSettings(type: AppSettingsType.bluetooth);
        }
      }
    } else if (permission == BciAppPermission.wifi) {
      await AppSettings.openAppSettings(type: AppSettingsType.wifi);
    }
  }

  static void showDeniedDialog(
      BuildContext context, String reason, BciAppPermission p) {
    Get.dialog(Column(
      children: [
        Center(
          child: Padding(
            padding: EdgeInsets.symmetric(horizontal: 10),
            child: Text(
              reason,
              textAlign: TextAlign.center,
              style: TextStyle(
                color: Colors.black,
                fontSize: 12,
              ),
            ),
          ),
        ),
        ElevatedButton(
          onPressed: () async {
            Get.back();
            await PermissionUtil.openPermission(p);
          },
          child: Text('去开启'),
        ),
      ],
    ));
  }

  static Future<bool> requestPermissions(BuildContext context,
      {BciDeviceType type = BciDeviceType.crimson}) async {
    if (type == BciDeviceType.crimson) {
      final deviceInfoPlugin = DeviceInfoPlugin();
      if (Platform.isAndroid) {
        final androidInfo = await deviceInfoPlugin.androidInfo;
        if (!androidInfo.isPhysicalDevice) return true;
        if (androidInfo.version.sdkInt >= 31) {
          loggerApp.i('request bluetooth scan & connect permission');
          await [
            Permission.bluetoothScan,
            Permission.bluetoothConnect
          ].request();
        } else {
          // await [Permission.locationWhenInUse, Permission.bluetooth].request();
          await Permission.locationWhenInUse.request();
        }
      } else if (Platform.isIOS) {
        final iosInfo = await deviceInfoPlugin.iosInfo;
        if (!iosInfo.isPhysicalDevice) return true;
        // if (Version.parse(iosInfo.systemVersion) < Version.parse('13.0')) {
        //   return true;
        // }
        await Permission.bluetooth.request();
      }
      final p = await blePermission;
      if (p == BciAppPermission.bluetooth) {
        showDeniedDialog(context, '蓝牙未打开\n\n请先打开蓝牙', p);
        return false;
      }
      if (p == BciAppPermission.location) {
        showDeniedDialog(context, '为了能够搜索到附近的蓝牙头环，需要开启定位权限', p);
        return false;
      }
    }

    return true;
  }

  static Future<void> requestIgnoreBatteryOptimizations(
      BuildContext context) async {
    if (Platform.isAndroid) {
      await PermissionUtil.request(Permission.ignoreBatteryOptimizations);
    }
  }
}
