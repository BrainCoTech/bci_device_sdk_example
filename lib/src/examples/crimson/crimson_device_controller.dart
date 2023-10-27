import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:libcmsn/libcmsn.dart';
import 'package:bci_device_sdk_example/logger.dart';
import 'package:liboxyz/liboxyz.dart';
import 'package:path_provider/path_provider.dart';
import 'package:bci_device_sdk_example/main.dart';
import 'package:dio/dio.dart';

import '../oxyzen/oxyzen_device_controller.dart';

const int eegXRange = 1000;
const int imuXRange = 100;
const int _imuMaxLen = imuXRange ~/ 2;

class CrimsonDeviceController extends GetxController
    with StreamSubscriptionsMixin, DeviceValues {
  final device = BciDeviceProxy.instance;
  final firmware = BciDeviceProxy.instance.deviceInfo.firmwareRevision.obs;

  final eegSeqNum = RxnInt(null);
  final imuSeqNum = RxnInt(null);

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

  final _eegValues = <double>[];
  final _imuModels = <ImuModel>[];

  Timer? _displayTimer;

  @override
  void onInit() async {
    super.onInit();

    addListenerEEG();
    addListenerIMU();
    if (BciDeviceManager.bondDevice is! CrimsonDevice) return;
    disableOrientationCheck.value =
        (BciDeviceManager.bondDevice as CrimsonDevice).disableOrientationCheck;
  }

  @override
  void onClose() async {
    _displayTimer?.cancel();
    _displayTimer = null;
    clearSubscriptions();
    clearOtaSubscriptions();
  }

  void addListenerEEG() {
    clearSubscriptions();
    subscriptions.add(device.onEEGData.listen((event) {
      eegSeqNum.value = event.seqNum;
      _eegValues.addAll(event.eeg);
      if (_eegValues.length > eegXRange) {
        _eegValues.removeRange(0, _eegValues.length - eegXRange);
      }
      // loggerApp.i('eegSeqNum=${eegSeqNum.value}, len=${_eegValues.length}');
      // loggerApp.i('eegSeqNum=${eegSeqNum.value}, ${_eegValues.first}');
      eegValues.value = _eegValues;
    }));

    // subscriptions.add(BciDeviceProxy.instance.onBrainWave.listen((stats) {
    // loggerApp.i('-----------onBrainWave-----------');
    // loggerApp.i('stats.alpha=${stats.alpha}');
    // loggerApp.i('stats.theta=${stats.theta}');
    // print('stats.delta=${stats.delta}');
    // print('stats.lowBeta=${stats.lowBeta}');
    // print('stats.highBeta=${stats.highBeta}');
    // print('stats.gamma=${stats.gamma}');
    // }));

    // subscriptions.add(BciDeviceProxy.instance.onDrowsiness.listen((val) {
    //   loggerApp.i(
    //       '[${BciDeviceProxy.instance.name}] drowsiness=${val.toStringAsFixed(1)}');
    // }));

    // subscriptions.add(BciDeviceProxy.instance.onMeditation.listen((val) {
    //   loggerApp.i(
    //       '[${BciDeviceProxy.instance.name}] meditation=${val.toStringAsFixed(1)}');
    // }));

    subscriptions.add(device.onAttention.listen((e) {
      loggerApp.i('onAttention, $e');
      attentionList.add(e);
    }));
    subscriptions.add(device.onMeditation.listen((e) {
      loggerApp.i('onMeditation, $e');
      calmnessList.add(e);
    }));
    // subscriptions.add(BciDeviceProxy.instance.onImuData.listen((imu) {
    //   loggerApp.i(
    //       '[${BciDeviceProxy.instance.name}] IMU, head:${imu.head}, body:${imu.body}');
    // }));
  }

  void addListenerIMU() {
    subscriptions.add(device.onImuData.listen((event) {
      imuSeqNum.value = event.seqNum;
      _imuModels.add(event);
      if (_imuModels.length > _imuMaxLen) {
        _imuModels.removeRange(0, _imuModels.length - _imuMaxLen);
      }
      // loggerApp.i(
      //     'imuSeqNum=${imuSeqNum.value}, _imuModels.length=${_imuModels.length}, '
      //     'acc len=${_imuModels.map((e) => e.acc.x).expand((e) => e).length}, '
      //     'gyro len=${_imuModels.map((e) => e.gyro.x).expand((e) => e).length}, ');
      // 'euler len=${_imuModels.map((e) => e.eulerAngle.yaw).expand((e) => e).length}');
      // imuModels.value = _imuModels;

      accX.value = _imuModels.map((e) => e.acc.x).expand((e) => e).toList();
      accY.value = _imuModels.map((e) => e.acc.y).expand((e) => e).toList();
      accZ.value = _imuModels.map((e) => e.acc.z).expand((e) => e).toList();
      gyroX.value =
          _imuModels.map((e) => e.gyro?.x ?? []).expand((e) => e).toList();
      gyroY.value =
          _imuModels.map((e) => e.gyro?.y ?? []).expand((e) => e).toList();
      gyroZ.value =
          _imuModels.map((e) => e.gyro?.z ?? []).expand((e) => e).toList();
      yaw.value = _imuModels
          .where((e) => e.eulerAngle != null)
          .map((e) => e.eulerAngle!.yaw)
          .expand((e) => e)
          .toList();
      pitch.value = _imuModels
          .where((e) => e.eulerAngle != null)
          .map((e) => e.eulerAngle!.pitch)
          .expand((e) => e)
          .toList();
      roll.value = _imuModels
          .where((e) => e.eulerAngle != null)
          .map((e) => e.eulerAngle!.roll)
          .expand((e) => e)
          .toList();
    }));
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
    if (_otaRunning) return;
    if (BciDeviceManager.bondDevice is! CrimsonDevice) return;
    _otaRunning = true;
    final headband = BciDeviceManager.bondDevice as CrimsonDevice;
    try {
      final filePath = ConfigController.filePath.value;
      if (filePath.isNotEmpty) {
        await _startDfu(headband, filePath);
      } else {
        if (!kDebugMode) return;
        const url =
            'https://oss.brainco.cn/crimson-firmware/updates/FW_DFU_Crimson_V1.1.6.zip';
        loggerApp.i('download url=$url');
        dfuProgress.value = '';
        final storageDir = await getApplicationSupportDirectory();
        final dstPath = '${storageDir.path}/rom.zip';
        final dio = Dio();
        await dio.download(
          url,
          dstPath,
          onReceiveProgress: (count, total) async {
            final progress = (count * 100.0 / total).toStringAsFixed(1);
            loggerApp.i('download firmware progress = $progress');
            dfuProgress.value = 'download firmware progress = $progress';
            if (count == total) {
              await _startDfu(headband, dstPath);
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

  void clearOtaSubscriptions() {
    for (var subscription in _otaSubscriptions) {
      subscription.cancel();
    }
    _otaSubscriptions.clear();
  }

  Future _startDfu(CrimsonDevice device, String zipFilePath) async {
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
