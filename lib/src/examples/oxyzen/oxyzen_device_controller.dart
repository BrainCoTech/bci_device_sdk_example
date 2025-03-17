import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:bci_device_sdk_example/logger.dart';
import 'package:liboxyz/liboxyz.dart';
import 'package:liboxyz/proto/zenlite_data.pb.dart';
import 'package:bci_device_sdk_example/main.dart';

const int eegXRange = 1000;
const int imuXRange = 100;
const int _imuMaxLen = imuXRange ~/ 2;

class ConfigController {
  static final filePath = ''.obs;
}

mixin DeviceValues {
  final calmnessList = RxList<double>();
  final attentionList = RxList<double>();
}

class OxyzenDeviceController extends GetxController
    with StreamSubscriptionsMixin, DeviceValues {
  final device = BciDeviceManager.bondDevice as OxyZenDevice;
  final firmware = BciDeviceProxy.instance.deviceInfo.firmwareVersion.obs;
  final deviceName = BciDeviceProxy.instance.name.obs;

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

  final _eegValues = <double>[];
  final _imuModels = <ImuModel>[];

  final _ppgValues = <PpgRawModel>[];
  final ppgValues = <PpgRawModel>[].obs;

  Timer? _displayTimer;

  @override
  void onInit() async {
    super.onInit();

    addListenData();
    addListenerEEG();
    addListenerIMU();
    addListenerPpg();
    disableOrientationCheck.value = device.disableOrientationCheck;
  }

  void clearOtaSubscriptions() {
    for (var subscription in _otaSubscriptions) {
      subscription.cancel();
    }
    _otaSubscriptions.clear();
  }

  @override
  void onClose() async {
    _displayTimer?.cancel();
    _displayTimer = null;
    clearSubscriptions();
    clearOtaSubscriptions();
  }

  void addListenData() {
    clearSubscriptions();
    BciDeviceManager.onDeviceUnbind.listen((_) async {
      loggerApp.i('device unbind, go scan screen');
    }).subscribedBy(this);
    BciDeviceProxy.instance.onDeviceConnected.where((e) => e).listen((_) async {
      deviceName.value = BciDeviceProxy.instance.name;
    }).subscribedBy(this);
    BciDeviceProxy.instance.onDeviceEvent
        .where((e) => e == BciDeviceEvent.rename)
        .listen((_) async {
      deviceName.value = BciDeviceProxy.instance.name;
    }).subscribedBy(this);
    BciDeviceProxy.instance.onDeviceFirmware.listen((firmware) async {
      this.firmware.value = firmware;
    }).subscribedBy(this);

    subscriptions.add(device.onCalmness.listen((e) {
      calmnessList.add(e);
    }));
    subscriptions.add(device.onAttention.listen((e) {
      attentionList.add(e);
    }));
  }

  void addListenerEEG() {
    subscriptions.add(device.onEEGData.listen((event) {
      eegSeqNum.value = event.seqNum;
      _eegValues.addAll(event.eeg);
      if (_eegValues.length > eegXRange) {
        _eegValues.removeRange(0, _eegValues.length - eegXRange);
      }
      eegValues.value = _eegValues;
    }));

    final headband = BciDeviceManager.bondDevice;
    if (headband is OxyZenDevice) {
      subscriptions.add(BciDeviceProxy.instance.onSleepEvent.listen((e) {
        loggerApp.i('[${BciDeviceProxy.instance.name}] event=$e');
      }));
    }
  }

  void addListenerIMU() {
    subscriptions.add(device.onImuData.listen((event) {
      imuSeqNum.value = event.seqNum;
      _imuModels.add(event);
      if (_imuModels.length > _imuMaxLen) {
        _imuModels.removeRange(0, _imuModels.length - _imuMaxLen);
      }
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

  void addListenerPpg() {
    final device = BciDeviceManager.bondDevice;
    if (device is! OxyZenDevice) return;
    subscriptions.add(device.onReceiveZenLiteData
        .where((e) => e.hasPpgModule() && e.ppgModule.hasData())
        .map((e) => e.ppgModule.data)
        .listen((data) {
      ppgData.value = data;
    }));
    subscriptions.add(device.onRawPPGData.listen((e) {
      final ppgSeqNum = e.seqNum;
      if (ppgSeqNum == 0) return;
      _ppgValues.add(e);
      if (_ppgValues.length > 1000) {
        _ppgValues.removeAt(0);
      }
      ppgValues.value = _ppgValues;
    }));
  }

  void setOrientationCheck(disabled) {
    final device = BciDeviceManager.bondDevice as OxyZenDevice;
    device.disableOrientationCheck = disabled;
    disableOrientationCheck.value = disabled;
    loggerApp.i('setOrientationCheck $disabled');
  }

  bool _otaRunning = false;

  final List<StreamSubscription> _otaSubscriptions = [];

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
            'https://app.brainco.cn/crimson-firmware/updates/DFU_zenlite_V2.2.0.zip';
        loggerApp.i('download url=$url');
        dfuProgress.value = '';
        final file = await OtaFileCacheManager()
            .getSingleFileWithSuffix(url, suffix: '.zip');
        await _startDfu(device, file.path);
      }
    } catch (e) {
      loggerApp.e('download firmware error, $e');
      dfuProgress.value = 'download firmware error';
      _otaRunning = false;
    }
  }

  Future _startDfu(OxyZenDevice device, String zipFilePath) async {
    clearOtaSubscriptions();
    device.dfuHandler.msgController.listen((e) {
      final index = e[0] as int;
      final total = e[1] as int;
      final msg = e[2] as String;
      loggerApp.i('DFU: $index/$total');
      dfuProgress.value = msg;
    }).addToList(_otaSubscriptions);
    device.dfuStateStream.listen((state) {
      switch (state) {
        case OtaState.success:
        case OtaState.failed:
          _otaRunning = false;
          break;
        default:
          break;
      }
    }).addToList(_otaSubscriptions);
    final ret = device.startDfu(zipFilePath);
    if (!ret) clearOtaSubscriptions();
  }
}
