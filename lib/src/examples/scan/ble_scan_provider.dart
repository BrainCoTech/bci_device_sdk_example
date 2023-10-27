// ignore_for_file: unnecessary_import

import 'dart:async';
import 'dart:io';

import 'package:device_info_plus/device_info_plus.dart';
import 'package:flutter/material.dart';
import 'package:bci_device_sdk_example/main.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:bci_device_sdk/bci_device_sdk.dart';

import '../../../logger.dart';

class BleScanProvider extends ChangeNotifier {
  Future<void> init() async {
    final deviceInfoPlugin = DeviceInfoPlugin();
    if (Platform.isAndroid) {
      final androidInfo = await deviceInfoPlugin.androidInfo;
      if (androidInfo.version.sdkInt >= 31) {
        loggerApp.i('request Permission.bluetoothScan & bluetoothConnect');
        await [
          Permission.bluetoothScan,
          Permission.bluetoothConnect
        ].request();
      } else {
        await [Permission.locationWhenInUse].request();
      }
    } else if (Platform.isIOS || Platform.isWindows) {
      await [Permission.bluetooth].request();
    }
    await BleScanner.instance.startScan();
  }

  @override
  void dispose() async {
    await BleScanner.instance.stopScan();
    super.dispose();
  }
}
