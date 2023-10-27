import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:bci_device_sdk_example/logger.dart';
import 'package:liboxyz/liboxyz.dart';
import 'package:liboxyz/proto/zenlite_data.pb.dart';
import 'package:path_provider/path_provider.dart';
import 'package:bci_device_sdk_example/main.dart';
import 'package:dio/dio.dart';

const int eegXRange = 1000;
const int imuXRange = 100;

class ConfigController {
  static final filePath = ''.obs;
}

abstract class DeviceValues {
  final calmnessList = RxList<double>();
  final attentionList = RxList<double>();
}

class OxyzenDeviceController extends GetxController
    with StreamSubscriptionsMixin, DeviceValues {
  final device = BciDeviceProxy.instance;
  final firmware = BciDeviceProxy.instance.deviceInfo.firmwareRevision.obs;

  final eegSeqNum = RxnInt(null);
  final imuSeqNum = RxnInt(null);
  final ppgData = Rx<PpgModule_PpgData?>(null);

  final RxInt tabIndex = 0.obs;
  final RxList<double> eegValues = <double>[].obs;
  final RxList<double> accX = <double>[].obs;
  final RxList<double> accY = <double>[].obs;
  final RxList<double> accZ = <double>[].obs;
  final RxList<double> gyroX = <double>[].obs;
  final RxList<double> gyroY = <double>[].obs;
  final RxList<double> gyroZ = <double>[].obs;
  final RxList<double> yaw = <double>[].obs;
  final RxList<double> pitch = <double>[].obs;
  final RxList<double> roll = <double>[].obs;

  final RxString dfuProgress = ('').obs;
  final disableOrientationCheck = false.obs;

  @override
  void onInit() async {
    super.onInit();

    if (BciDeviceManager.bondDevice is! OxyZenDevice) return;
    disableOrientationCheck.value =
        (BciDeviceManager.bondDevice as OxyZenDevice).disableOrientationCheck;
  }

  void clearOtaSubscriptions() {
    for (var subscription in _otaSubscriptions) {
      subscription.cancel();
    }
    _otaSubscriptions.clear();
  }

  @override
  void onClose() async {
    clearSubscriptions();
    clearOtaSubscriptions();
  }

  void setOrientationCheck(disabled) {
    final device = BciDeviceManager.bondDevice as OxyZenDevice;
    device.disableOrientationCheck = disabled;
    disableOrientationCheck.value = disabled;
    loggerApp.i('setOrientationCheck $disabled');
  }

  bool _otaRunning = false;

  List<StreamSubscription> _otaSubscriptions = [];

  Future startDFU() async {
    loggerDevice.i('startDFU, _otaRunning=$_otaRunning');
    if (_otaRunning) return;
    if (BciDeviceManager.bondDevice is! OxyZenDevice) return;
    _otaRunning = true;
    final device = BciDeviceManager.bondDevice as OxyZenDevice;
    try {
      final filePath = ConfigController.filePath.value;
      if (filePath.isNotEmpty) {
        await _startDfu(device, filePath);
      } else {
        if (!kDebugMode) return;
        const url =
            'https://app.brainco.cn/crimson-firmware/updates/DFU_zenlite_V2.2.X.zip';
        loggerApp.i('download url=$url');
        dfuProgress.value = '';
        final storageDir = await getApplicationSupportDirectory();
        final zipFilePath = '${storageDir.path}/rom.zip';
        final dio = Dio();
        await dio.download(
          url,
          zipFilePath,
          onReceiveProgress: (count, total) async {
            final progress = (count * 100.0 / total).toStringAsFixed(1);
            loggerApp.i('download firmware progress = $progress');
            dfuProgress.value = 'download firmware progress = $progress';
            if (count == total) {
              await _startDfu(device, zipFilePath);
            }
          },
        );
      }
    } catch (e) {
      loggerApp.e('download firmware error, $e');
      dfuProgress.value = 'download firmware error';
      _otaRunning = false;
    }
  }

  Future _startDfu(OxyZenDevice device, String zipFilePath) async {
    clearOtaSubscriptions();

    device.otaMsgController.listen((msg) {
      dfuProgress.value = msg;
    }).addToList(_otaSubscriptions);

    device.otaStatusController.listen((status) {
      switch (status) {
        case OtaStatus.success:
        case OtaStatus.failed:
          _otaRunning = false;
          break;
        default:
          break;
      }
    }).addToList(_otaSubscriptions);

    device.startDfu(zipFilePath);
  }
}
