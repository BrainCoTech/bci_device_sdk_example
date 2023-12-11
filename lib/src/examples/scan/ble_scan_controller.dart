import 'dart:io';

import 'package:bci_device_sdk_example/logger.dart';
import 'package:device_info_plus/device_info_plus.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:bci_device_sdk/bci_device_sdk.dart';
import 'package:get/get.dart';

class BleScanController extends GetxController with StreamSubscriptionsMixin {
  final permission = BciAppPermission.normal.obs;

  @override
  void onInit() async {
    final deviceInfoPlugin = DeviceInfoPlugin();
    if (Platform.isAndroid) {
      final androidInfo = await deviceInfoPlugin.androidInfo;
      if (androidInfo.version.sdkInt >= 31) {
        loggerApp.i('request Permission.bluetoothScan & bluetoothConnect');
        await [Permission.bluetoothScan, Permission.bluetoothConnect].request();
      } else {
        await [Permission.locationWhenInUse].request();
      }
    } else if (Platform.isIOS || Platform.isWindows) {
      await [Permission.bluetooth].request();
    }
    onBlePermissionChanged.distinct().listen((e) {
      permission.value = e;
    }).subscribedBy(this);

    // BleScanner.winScanningMode = WinScanningMode.passive; // for crimson win
    BleScanner.ignoreRssi = false;
    // BleScanner.resultExpiredMilliseconds = 3000;
    await BleScanner.instance.startScan();

    super.onInit();
  }

  @override
  void onClose() async {
    clearSubscriptions();
    await BleScanner.instance.stopScan();
    super.onClose();
  }
}
